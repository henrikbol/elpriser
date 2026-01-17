from datetime import datetime, timedelta

import pandas as pd
import pytz
import requests
import uvicorn
from fastapi import FastAPI, Request
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates

app = FastAPI()
templates = Jinja2Templates(directory="src/static/")
app.mount("/static", StaticFiles(directory="src/static"), name="static")

POWER_RIGHT_NOW_URL = "https://api.energidataservice.dk/dataset/PowerSystemRightNow?offset=0&sort=Minutes1UTC%20DESC&timezone=utc"


def get_spot_prices(now):
    HOURS_PRIOR = 5
    query_time = now - timedelta(hours=30)
    SPOT_PRICE_URL = f"https://api.energidataservice.dk/dataset/DayAheadPrices?offset=0&start={query_time.strftime('%Y-%m-%dT%H:%M')}&filter=%7B%22PriceArea%22:[%22DK2%22]%7D&sort=TimeDK%20ASC"
    print(SPOT_PRICE_URL)
    response = requests.get(url=SPOT_PRICE_URL)
    records = response.json().get("records", [])
    _df = (
        pd.json_normalize(records)[["TimeDK", "DayAheadPriceDKK"]].set_index("TimeDK").sort_index()
    )
    _df.index = pd.to_datetime(_df.index)
    _df = _df.resample("h").mean()
    _df["DayAheadPriceDKK"] = (1.25 * _df["DayAheadPriceDKK"] / 1000.0).round(2)
    _df["SpotPriceLast24H"] = _df["DayAheadPriceDKK"].rolling(24).mean().round(2)
    _df.index = _df.index.strftime("%a %H:%M")
    lowest_index = _df.iloc[HOURS_PRIOR:]["DayAheadPriceDKK"].idxmin()
    lowest_price = _df.loc[lowest_index, "DayAheadPriceDKK"]
    return _df.iloc[25:52, :], HOURS_PRIOR, lowest_price, lowest_index


def get_power_right_now():
    response = requests.get(url=POWER_RIGHT_NOW_URL)
    records = response.json().get("records", [])
    _df = (
        pd.json_normalize(records)[
            [
                "Minutes1DK",
                "ProductionGe100MW",
                "ProductionLt100MW",
                "SolarPower",
                "OffshoreWindPower",
                "OnshoreWindPower",
            ]
        ]
        .set_index("Minutes1DK")
        .sort_index()
    )
    return _df


@app.get("/")
def return_board(request: Request):
    tz = pytz.timezone("Europe/Copenhagen")
    now = datetime.now(tz).replace(tzinfo=None)
    spot_prices, now_index, lowest_price, lowest_index = get_spot_prices(now)
    power_right_now = get_power_right_now()
    green = power_right_now.iloc[-1][["SolarPower", "OffshoreWindPower", "OnshoreWindPower"]].sum()
    total = power_right_now.iloc[-1].sum()

    return templates.TemplateResponse(
        "form.html",
        context={
            "request": request,
            "spot_labels": spot_prices.index.to_list(),
            "spot_values": spot_prices["DayAheadPriceDKK"].to_list(),
            "spot_values_rolling": spot_prices["SpotPriceLast24H"].fillna(0).to_list(),
            "now_index": now_index,
            "spot_title": f"{now: Spotpris %d. %b %Y kl. %H:%M} er {spot_prices.iloc[now_index, 0]:.2f} DKK",
            "spot_title2": f"Laveste pris er {lowest_index} til {lowest_price:.2f} DKK",
            "now_title": f"{green/total:.2%} Green energy",
            "now_labels": power_right_now.columns.to_list(),
            "now_values": power_right_now.iloc[-1].to_list(),
        },
    )


@app.get("/chrx")
def return_meeter(request: Request):
    return templates.TemplateResponse(
        "meter.html",
        context={
            "request": request,
        },
    )


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)
