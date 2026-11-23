pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Coordenadas por defecto (mismas que scripts/night-light; sobreescribibles por env)
    // Ubicación dinámica por IP en cada encendido (fallback a 8.5, -80.2)
    property string lat: Quickshell.env("WEATHER_LAT") || "8.5"
    property string lon: Quickshell.env("WEATHER_LON") || "-80.2"
    property string locationLabel: Quickshell.env("WEATHER_LOC") || "COCLÉ // PA"
    property bool locResolved: false

    Process {
        id: locProc
        command: [
            "curl", "-fsS", "--max-time", "4",
            "-A", "arch-niri-weather/1.0",
            "http://ip-api.com/json/?fields=status,city,regionName,countryCode,lat,lon"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const raw = this.text.trim();
                if (!raw) return;
                try {
                    const info = JSON.parse(raw);
                    if (info.status === "success" && info.lat !== undefined && info.lon !== undefined) {
                        if (!Quickshell.env("WEATHER_LAT")) root.lat = String(info.lat);
                        if (!Quickshell.env("WEATHER_LON")) root.lon = String(info.lon);
                        if (!Quickshell.env("WEATHER_LOC")) {
                            const place = (info.city || info.regionName || "LOCAL").toUpperCase();
                            const cc = (info.countryCode || "").toUpperCase();
                            root.locationLabel = cc ? (place + " // " + cc) : place;
                        }
                        root.locResolved = true;
                        root.refresh();
                    }
                } catch (e) {
                    console.warn("Weather: error al parsear geolocalización:", e);
                }
            }
        }
    }

    property bool loaded: false
    property bool loading: false
    property string errorMsg: ""

    property real temp: 0
    property real feelsLike: 0
    property real tempMax: 0
    property real tempMin: 0
    property int humidity: 0
    property real windSpeed: 0
    property int weatherCode: -1
    property bool isDay: true
    property string updatedAt: ""

    readonly property string condition: {
        const c = weatherCode;
        if (c === 0) return "CLEAR SKY";
        if (c === 1) return "MAINLY CLEAR";
        if (c === 2) return "PARTLY CLOUDY";
        if (c === 3) return "OVERCAST";
        if (c === 45 || c === 48) return "FOG";
        if (c >= 51 && c <= 57) return "DRIZZLE";
        if (c >= 61 && c <= 67) return "RAIN";
        if (c >= 71 && c <= 77) return "SNOW";
        if (c >= 80 && c <= 82) return "SHOWERS";
        if (c >= 95) return "THUNDERSTORM";
        return loaded ? "UNKNOWN" : "OFFLINE";
    }

    readonly property string glyph: {
        const c = weatherCode;
        if (c === 0 || c === 1) return isDay ? "󰖙" : "󰖔";
        if (c === 2) return isDay ? "󰖕" : "󰼱";
        if (c === 3) return "󰖐";
        if (c === 45 || c === 48) return "󰖑";
        if (c >= 51 && c <= 67) return "󰖗";
        if (c >= 71 && c <= 77) return "󰖘";
        if (c >= 80 && c <= 82) return "󰖖";
        if (c >= 95) return "󰖓";
        return "󰖐";
    }

    Process {
        id: fetchProc
        command: [
            "curl", "-fsSG", "--max-time", "6",
            "-A", "arch-niri-weather/1.0",
            "https://api.open-meteo.com/v1/forecast",
            "-d", "latitude=" + root.lat,
            "-d", "longitude=" + root.lon,
            "-d", "current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day",
            "-d", "daily=temperature_2m_max,temperature_2m_min",
            "-d", "timezone=auto",
            "-d", "forecast_days=1"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                const raw = this.text.trim();
                if (!raw) {
                    root.errorMsg = "NO RESPONSE";
                    return;
                }
                try {
                    const data = JSON.parse(raw);
                    if (data.current) {
                        root.temp = Number(data.current.temperature_2m);
                        root.feelsLike = Number(data.current.apparent_temperature);
                        root.humidity = Math.round(Number(data.current.relative_humidity_2m));
                        root.windSpeed = Number(data.current.wind_speed_10m);
                        root.weatherCode = parseInt(data.current.weather_code);
                        root.isDay = Number(data.current.is_day) === 1;
                    }
                    if (data.daily && data.daily.temperature_2m_max && data.daily.temperature_2m_min) {
                        root.tempMax = Number(data.daily.temperature_2m_max[0]);
                        root.tempMin = Number(data.daily.temperature_2m_min[0]);
                    }
                    root.loaded = true;
                    root.errorMsg = "";
                    root.updatedAt = Qt.formatDateTime(new Date(), "HH:mm");
                } catch (e) {
                    root.errorMsg = "PARSE ERROR";
                    console.warn("Weather: error al parsear Open-Meteo:", e);
                }
            }
        }
        onExited: code => {
            root.loading = false;
            if (code !== 0 && !root.loaded) {
                root.errorMsg = "OFFLINE";
            }
        }
    }

    function refresh() {
        if (fetchProc.running) return;
        root.loading = true;
        fetchProc.running = true;
    }

    Component.onCompleted: {
        if (!Quickshell.env("WEATHER_LAT") || !Quickshell.env("WEATHER_LON")) {
            locProc.running = true;
        }
    }

    Timer {
        interval: 1800000 // 30 minutos
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
