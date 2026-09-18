import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Io 

import "../../../../theme" 
import "../../../../theme/components" 

Item {
    id: weatherRoot
    
    // ==========================================
    // API KEYS FOR THIRD-PARTY PROVIDERS
    // ==========================================
    property string openWeatherApiKey: ""
    property string accuWeatherApiKey: ""

    // --- LOCATION PICKER STATE ---
    property string currentLocation: Settings.weatherLocation
    property real currentLat: Settings.weatherLat
    property real currentLon: Settings.weatherLon
    property bool isLocationPickerOpen: false
    property string locationSearchQuery: ""
    
    // --- UNIT STATE ---
    property bool isFahrenheit: Settings.weatherIsFahrenheit
    
    function getTemp(celsius) {
        return isFahrenheit ? Math.round((celsius * 9/5) + 32) : celsius;
    }

    function saveWeatherSettings() {
        Settings.setWeather(currentSource, currentLocation, currentLat, currentLon, isFahrenheit);
    }
    
    property var comprehensiveCities: [
        { name: "Kakkanad (Home)", country: "Kerala, India", isAuto: true, lat: 10.0158, lon: 76.3418 },
        { name: "Kochi", country: "Kerala, India", isAuto: false, lat: 9.9312, lon: 76.2673 },
        { name: "Thiruvananthapuram", country: "Kerala, India", isAuto: false, lat: 8.5241, lon: 76.9366 },
        { name: "Kozhikode", country: "Kerala, India", isAuto: false, lat: 11.2588, lon: 75.7804 },
        { name: "Thrissur", country: "Kerala, India", isAuto: false, lat: 10.5276, lon: 76.2144 },
        { name: "Bengaluru", country: "Karnataka, India", isAuto: false, lat: 12.9716, lon: 77.5946 },
        { name: "Chennai", country: "Tamil Nadu, India", isAuto: false, lat: 13.0827, lon: 80.2707 },
        { name: "Mumbai", country: "Maharashtra, India", isAuto: false, lat: 19.0760, lon: 72.8777 },
        { name: "Delhi", country: "India", isAuto: false, lat: 28.6139, lon: 77.2090 },
        { name: "Hyderabad", country: "Telangana, India", isAuto: false, lat: 17.3850, lon: 78.4867 },
        { name: "Kolkata", country: "West Bengal, India", isAuto: false, lat: 22.5726, lon: 88.3639 },
        { name: "Dubai", country: "United Arab Emirates", isAuto: false, lat: 25.2048, lon: 55.2708 },
        { name: "Singapore", country: "Singapore", isAuto: false, lat: 1.3521, lon: 103.8198 },
        { name: "Tokyo", country: "Japan", isAuto: false, lat: 35.6895, lon: 139.6917 },
        { name: "London", country: "United Kingdom", isAuto: false, lat: 51.5085, lon: -0.1257 },
        { name: "New York", country: "United States", isAuto: false, lat: 40.7143, lon: -74.006 }
    ]
    
    property var filteredCities: comprehensiveCities

    // --- SOURCE PICKER STATE ---
    property string currentSource: Settings.weatherSource
    property bool isSourcePickerOpen: false
    property var sourceDatabase: [
        { name: "Open-Meteo", icon: "\uf0c2" },
        { name: "AccuWeather", icon: "\uf185" },
        { name: "OpenWeather", icon: "\uf043" }
    ]

    // --- TAB STATES ---
    property int activeTab: 0        
    property int hourlyActiveTab: 0  

    // --- LIVE WEATHER DATA ---
    property int currentTemp: 0
    property int feelsLike: 0
    property int dayTemp: 0
    property int nightTemp: 0
    property string weatherDesc: "Loading..."
    property string weatherIcon: "\uf0c2" 
    
    property string precipChance: "0%"
    property string precipVolume: "0.0 mm"
    property string windSpeed: "0 km/h"
    property int windDirection: 0 
    property int aqi: 0
    property string aqiDesc: "..."
    property string humidity: "0%"
    property int dewPoint: 0

    property real sunProgress: 0.0 
    property string sunriseTime: "--:--"
    property string sunsetTime: "--:--"
    property real moonProgress: 0.0
    property string moonriseTime: "--:--"
    property string moonsetTime: "--:--"
    property string moonPhase: "..."

    ListModel { id: hourlyModel }
    property var dailyWeather: []

    // ==========================================
    // BACKEND JAVASCRIPT API ENGINE
    // ==========================================
    Component.onCompleted: {
        fetchWeatherData(currentLat, currentLon);
    }

    function refreshAllCanvases() {
        if (typeof sunCanvas !== "undefined") sunCanvas.requestPaint()
        if (typeof moonCanvas !== "undefined") moonCanvas.requestPaint()
        if (typeof hourlyWeatherCanvas !== "undefined") hourlyWeatherCanvas.requestPaint()
        if (typeof hourlyPrecipCanvas !== "undefined") hourlyPrecipCanvas.requestPaint()
        if (typeof hourlyAqiCanvas !== "undefined") hourlyAqiCanvas.requestPaint()
        if (typeof hourlyWindCanvas !== "undefined") hourlyWindCanvas.requestPaint()
        if (typeof weatherCanvas !== "undefined") weatherCanvas.requestPaint()
        if (typeof precipCanvas !== "undefined") precipCanvas.requestPaint()
        if (typeof aqiCanvas !== "undefined") aqiCanvas.requestPaint()
        if (typeof windCanvas !== "undefined") windCanvas.requestPaint()
    }

    function getFaIconFromWmo(code, isDay) {
        if (code === 0) return isDay ? "\uf185" : "\uf186";
        if (code === 1 || code === 2) return isDay ? "\uf185" : "\uf0c2";
        if (code === 3 || (code >= 45 && code <= 48)) return "\uf0c2";
        if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "\uf043";
        if (code >= 71 && code <= 77) return "\uf2dc";
        if (code >= 95) return "\uf0e7";
        return isDay ? "\uf185" : "\uf0c2";
    }

    function getFaIconFromOwm(id, isDay) {
        if (id >= 200 && id < 300) return "\uf0e7";
        if (id >= 300 && id < 600) return "\uf043";
        if (id >= 600 && id < 700) return "\uf2dc";
        if (id >= 700 && id < 800) return "\uf0c2";
        if (id === 800) return isDay ? "\uf185" : "\uf186";
        return "\uf0c2";
    }

    function getFaIconFromAccu(iconId, isDay) {
        if (iconId <= 2) return isDay ? "\uf185" : "\uf186";
        if (iconId <= 6) return "\uf0c2";
        if (iconId <= 11) return "\uf0c2";
        if (iconId >= 12 && iconId <= 18) return "\uf043";
        if (iconId >= 19 && iconId <= 29) return "\uf2dc";
        if (iconId >= 33 && iconId <= 34) return "\uf186";
        return "\uf0c2";
    }

    function getAqiDesc(val) {
        if (val <= 50) return "Fair";
        if (val <= 100) return "Moderate";
        if (val <= 150) return "Poor";
        if (val <= 200) return "Unhealthy";
        return "Hazardous";
    }

    function getMoonPhaseName(phase) {
        if (phase === 0 || phase === 1) return "New Moon";
        if (phase < 0.25) return "Waxing Crescent";
        if (phase === 0.25) return "First Quarter";
        if (phase < 0.5) return "Waxing Gibbous";
        if (phase === 0.5) return "Full Moon";
        if (phase < 0.75) return "Waning Gibbous";
        if (phase === 0.75) return "Last Quarter";
        return "Waning Crescent";
    }

    function fetchWeatherData(lat, lon) {
        weatherRoot.currentLat = lat;
        weatherRoot.currentLon = lon;

        if (weatherRoot.currentSource === "OpenWeather") {
            fetchOpenWeatherData(lat, lon);
        } else if (weatherRoot.currentSource === "AccuWeather") {
            fetchAccuWeatherData(lat, lon);
        } else {
            fetchOpenMeteoData(lat, lon);
        }
    }

    // ==========================================
    // 1. OPEN-METEO PROVIDER
    // ==========================================
    function fetchOpenMeteoData(lat, lon) {
        var url = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon + 
                  "&current=temperature_2m,apparent_temperature,is_day,precipitation,weather_code,wind_speed_10m,wind_direction_10m,relative_humidity_2m,dew_point_2m" + 
                  "&hourly=temperature_2m,precipitation,weather_code,wind_speed_10m" + 
                  "&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,precipitation_sum,precipitation_probability_max,wind_speed_10m_max,moonrise,moonset,moon_phase" + 
                  "&timezone=auto";

        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    
                    weatherRoot.currentTemp = Math.round(data.current.temperature_2m);
                    weatherRoot.feelsLike = Math.round(data.current.apparent_temperature);
                    weatherRoot.dayTemp = Math.round(data.daily.temperature_2m_max[0]);
                    weatherRoot.nightTemp = Math.round(data.daily.temperature_2m_min[0]);
                    weatherRoot.weatherDesc = (data.current.weather_code === 0) ? "Clear Sky" : ((data.current.weather_code <= 3) ? "Partly Cloudy" : "Overcast");
                    weatherRoot.weatherIcon = getFaIconFromWmo(data.current.weather_code, data.current.is_day);
                    
                    weatherRoot.precipChance = (data.daily.precipitation_probability_max ? data.daily.precipitation_probability_max[0] : 0) + "%";
                    var dayPrecip = data.daily.precipitation_sum ? data.daily.precipitation_sum[0] : data.current.precipitation;
                    weatherRoot.precipVolume = Number(dayPrecip).toFixed(1) + " mm";
                    
                    weatherRoot.windSpeed = Math.round(data.current.wind_speed_10m) + " km/h";
                    weatherRoot.windDirection = Math.round(data.current.wind_direction_10m);
                    weatherRoot.humidity = Math.round(data.current.relative_humidity_2m) + "%";
                    weatherRoot.dewPoint = Math.round(data.current.dew_point_2m);

                    let now = new Date();
                    let sunrise = new Date(data.daily.sunrise[0]);
                    let sunset = new Date(data.daily.sunset[0]);
                    weatherRoot.sunriseTime = sunrise.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', hour12: false});
                    weatherRoot.sunsetTime = sunset.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', hour12: false});
                    weatherRoot.sunProgress = Math.max(0, Math.min(1, (now.getTime() - sunrise.getTime()) / (sunset.getTime() - sunrise.getTime())));
                    
                    let moonrise = data.daily.moonrise[0] ? new Date(data.daily.moonrise[0]) : new Date();
                    let moonset = data.daily.moonset[0] ? new Date(data.daily.moonset[0]) : new Date(now.getTime() + 86400000);
                    weatherRoot.moonriseTime = data.daily.moonrise[0] ? moonrise.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', hour12: false}) : "--:--";
                    weatherRoot.moonsetTime = data.daily.moonset[0] ? moonset.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', hour12: false}) : "--:--";
                    weatherRoot.moonPhase = getMoonPhaseName(data.daily.moon_phase[0]);
                    weatherRoot.moonProgress = Math.max(0, Math.min(1, (now.getTime() - moonrise.getTime()) / (moonset.getTime() - moonrise.getTime())));

                    hourlyModel.clear();
                    let currentHourIdx = 0;
                    for (let i = 0; i < data.hourly.time.length; i++) {
                        if (new Date(data.hourly.time[i]) >= now) { currentHourIdx = i > 0 ? i - 1 : 0; break; }
                    }
                    for (let i = 0; i < 7; i++) {
                        let idx = currentHourIdx + i;
                        if (idx >= data.hourly.time.length) break;
                        let t = new Date(data.hourly.time[idx]);
                        hourlyModel.append({
                            time: i === 0 ? "Now" : t.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', hour12: false}),
                            icon: getFaIconFromWmo(data.hourly.weather_code[idx], 1),
                            temp: Math.round(data.hourly.temperature_2m[idx]),
                            precip: Number(data.hourly.precipitation[idx]).toFixed(1),
                            wind: Math.round(data.hourly.wind_speed_10m[idx]),
                            aqi: 20
                        });
                    }

                    const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                    let newDaily = [];
                    for (let i = 0; i < 7; i++) {
                        let parts = data.daily.time[i].split("-");
                        let dateObj = new Date(parseInt(parts[0]), parseInt(parts[1]) - 1, parseInt(parts[2]));
                        newDaily.push({
                            day: (i === 0) ? "Today" : dayNames[dateObj.getDay()],
                            date: ("0" + dateObj.getDate()).slice(-2) + "/" + ("0" + (dateObj.getMonth() + 1)).slice(-2),
                            dayIcon: getFaIconFromWmo(data.daily.weather_code[i], 1),
                            nightIcon: getFaIconFromWmo(data.daily.weather_code[i], 0),
                            high: Math.round(data.daily.temperature_2m_max[i]),
                            low: Math.round(data.daily.temperature_2m_min[i]),
                            precip: Number(data.daily.precipitation_sum[i]).toFixed(1),
                            wind: Math.round(data.daily.wind_speed_10m_max[i]),
                            aqi: 20
                        });
                    }
                    weatherRoot.dailyWeather = newDaily;
                    fetchAqiData(lat, lon);
                } catch (e) {
                    console.log("Open-Meteo Error: " + e);
                }
            }
        }
        xhr.send();
    }

    // ==========================================
    // 2. OPENWEATHER PROVIDER
    // ==========================================
    function fetchOpenWeatherData(lat, lon) {
        if (!weatherRoot.openWeatherApiKey || weatherRoot.openWeatherApiKey.trim() === "") {
            weatherRoot.weatherDesc = "Add OpenWeather Key";
            return;
        }

        var key = weatherRoot.openWeatherApiKey.trim();
        var curUrl = "https://api.openweathermap.org/data/2.5/weather?lat=" + lat + "&lon=" + lon + "&units=metric&appid=" + key;
        var fcUrl = "https://api.openweathermap.org/data/2.5/forecast?lat=" + lat + "&lon=" + lon + "&units=metric&appid=" + key;

        var xhrCur = new XMLHttpRequest();
        xhrCur.open("GET", curUrl);
        xhrCur.onreadystatechange = function() {
            if (xhrCur.readyState === XMLHttpRequest.DONE && xhrCur.status === 200) {
                var cur = JSON.parse(xhrCur.responseText);
                weatherRoot.currentTemp = Math.round(cur.main.temp);
                weatherRoot.feelsLike = Math.round(cur.main.feels_like);
                weatherRoot.weatherDesc = cur.weather[0].main;
                weatherRoot.weatherIcon = getFaIconFromOwm(cur.weather[0].id, true);
                weatherRoot.windSpeed = Math.round(cur.wind.speed * 3.6) + " km/h";
                weatherRoot.windDirection = Math.round(cur.wind.deg || 0);
                weatherRoot.humidity = cur.main.humidity + "%";
                weatherRoot.dewPoint = Math.round(cur.main.temp - ((100 - cur.main.humidity) / 5));

                let now = new Date();
                let sunrise = new Date(cur.sys.sunrise * 1000);
                let sunset = new Date(cur.sys.sunset * 1000);
                weatherRoot.sunriseTime = sunrise.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', hour12: false});
                weatherRoot.sunsetTime = sunset.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', hour12: false});
                weatherRoot.sunProgress = Math.max(0, Math.min(1, (now.getTime() - sunrise.getTime()) / (sunset.getTime() - sunrise.getTime())));

                var xhrFc = new XMLHttpRequest();
                xhrFc.open("GET", fcUrl);
                xhrFc.onreadystatechange = function() {
                    if (xhrFc.readyState === XMLHttpRequest.DONE && xhrFc.status === 200) {
                        var fc = JSON.parse(xhrFc.responseText);
                        hourlyModel.clear();
                        for (let i = 0; i < Math.min(7, fc.list.length); i++) {
                            let item = fc.list[i];
                            let t = new Date(item.dt * 1000);
                            hourlyModel.append({
                                time: i === 0 ? "Now" : t.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', hour12: false}),
                                icon: getFaIconFromOwm(item.weather[0].id, true),
                                temp: Math.round(item.main.temp),
                                precip: item.rain && item.rain["3h"] ? Number(item.rain["3h"]).toFixed(1) : "0.0",
                                wind: Math.round(item.wind.speed * 3.6),
                                aqi: 20
                            });
                        }

                        const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                        let daysGroup = {};
                        for (let i = 0; i < fc.list.length; i++) {
                            let it = fc.list[i];
                            let d = new Date(it.dt * 1000);
                            let k = d.getFullYear() + "-" + d.getMonth() + "-" + d.getDate();
                            if (!daysGroup[k]) daysGroup[k] = { temps: [], date: d, id: it.weather[0].id, wind: it.wind.speed * 3.6 };
                            daysGroup[k].temps.push(it.main.temp);
                        }
                        let newDaily = [];
                        let idx = 0;
                        for (let k in daysGroup) {
                            let g = daysGroup[k];
                            let highT = Math.round(Math.max.apply(null, g.temps));
                            let lowT = Math.round(Math.min.apply(null, g.temps));
                            newDaily.push({
                                day: idx === 0 ? "Today" : dayNames[g.date.getDay()],
                                date: ("0" + g.date.getDate()).slice(-2) + "/" + ("0" + (g.date.getMonth() + 1)).slice(-2),
                                dayIcon: getFaIconFromOwm(g.id, true),
                                nightIcon: getFaIconFromOwm(g.id, false),
                                high: highT,
                                low: lowT,
                                precip: "0.5",
                                wind: Math.round(g.wind),
                                aqi: 20
                            });
                            idx++;
                            if (newDaily.length >= 7) break;
                        }
                        weatherRoot.dailyWeather = newDaily;
                        if (newDaily.length > 0) {
                            weatherRoot.dayTemp = newDaily[0].high;
                            weatherRoot.nightTemp = newDaily[0].low;
                        }
                        fetchAqiData(lat, lon);
                    }
                }
                xhrFc.send();
            }
        }
        xhrCur.send();
    }

    // ==========================================
    // 3. ACCUWEATHER PROVIDER
    // ==========================================
    function fetchAccuWeatherData(lat, lon) {
        if (!weatherRoot.accuWeatherApiKey || weatherRoot.accuWeatherApiKey.trim() === "") {
            weatherRoot.weatherDesc = "Add AccuWeather Key";
            return;
        }

        var key = weatherRoot.accuWeatherApiKey.trim();
        var geoUrl = "http://dataservice.accuweather.com/locations/v1/cities/geoposition/search?apikey=" + key + "&q=" + lat + "," + lon;

        var xhrGeo = new XMLHttpRequest();
        xhrGeo.open("GET", geoUrl);
        xhrGeo.onreadystatechange = function() {
            if (xhrGeo.readyState === XMLHttpRequest.DONE && xhrGeo.status === 200) {
                var loc = JSON.parse(xhrGeo.responseText);
                var locKey = loc.Key;

                var curUrl = "http://dataservice.accuweather.com/currentconditions/v1/" + locKey + "?apikey=" + key + "&details=true";
                var xhrCur = new XMLHttpRequest();
                xhrCur.open("GET", curUrl);
                xhrCur.onreadystatechange = function() {
                    if (xhrCur.readyState === XMLHttpRequest.DONE && xhrCur.status === 200) {
                        var curArr = JSON.parse(xhrCur.responseText);
                        if (curArr.length > 0) {
                            var cur = curArr[0];
                            weatherRoot.currentTemp = Math.round(cur.Temperature.Metric.Value);
                            weatherRoot.feelsLike = Math.round(cur.RealFeelTemperature.Metric.Value);
                            weatherRoot.weatherDesc = cur.WeatherText;
                            weatherRoot.weatherIcon = getFaIconFromAccu(cur.WeatherIcon, cur.IsDayTime);
                            weatherRoot.windSpeed = Math.round(cur.Wind.Speed.Metric.Value) + " km/h";
                            weatherRoot.windDirection = cur.Wind.Direction.Degrees;
                            weatherRoot.humidity = cur.RelativeHumidity + "%";
                            weatherRoot.dewPoint = cur.DewPoint ? Math.round(cur.DewPoint.Metric.Value) : 24;
                        }
                    }
                }
                xhrCur.send();

                var dailyUrl = "http://dataservice.accuweather.com/forecasts/v1/daily/5day/" + locKey + "?apikey=" + key + "&details=true&metric=true";
                var xhrDaily = new XMLHttpRequest();
                xhrDaily.open("GET", dailyUrl);
                xhrDaily.onreadystatechange = function() {
                    if (xhrDaily.readyState === XMLHttpRequest.DONE && xhrDaily.status === 200) {
                        var df = JSON.parse(xhrDaily.responseText);
                        const dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
                        let newDaily = [];
                        for (let i = 0; i < df.DailyForecasts.length; i++) {
                            let it = df.DailyForecasts[i];
                            let d = new Date(it.Date);
                            newDaily.push({
                                day: i === 0 ? "Today" : dayNames[d.getDay()],
                                date: ("0" + d.getDate()).slice(-2) + "/" + ("0" + (d.getMonth() + 1)).slice(-2),
                                dayIcon: getFaIconFromAccu(it.Day.Icon, true),
                                nightIcon: getFaIconFromAccu(it.Night.Icon, false),
                                high: Math.round(it.Temperature.Maximum.Value),
                                low: Math.round(it.Temperature.Minimum.Value),
                                precip: (it.Day.PrecipitationProbability || 0).toString(),
                                wind: Math.round(it.Day.Wind.Speed.Value),
                                aqi: 20
                            });
                        }
                        weatherRoot.dailyWeather = newDaily;
                        if (newDaily.length > 0) {
                            weatherRoot.dayTemp = newDaily[0].high;
                            weatherRoot.nightTemp = newDaily[0].low;
                        }
                        refreshAllCanvases();
                    }
                }
                xhrDaily.send();

                var hourlyUrl = "http://dataservice.accuweather.com/forecasts/v1/hourly/12hour/" + locKey + "?apikey=" + key + "&details=true&metric=true";
                var xhrHourly = new XMLHttpRequest();
                xhrHourly.open("GET", hourlyUrl);
                xhrHourly.onreadystatechange = function() {
                    if (xhrHourly.readyState === XMLHttpRequest.DONE && xhrHourly.status === 200) {
                        var hf = JSON.parse(xhrHourly.responseText);
                        hourlyModel.clear();
                        for (let i = 0; i < Math.min(7, hf.length); i++) {
                            let it = hf[i];
                            let t = new Date(it.DateTime);
                            hourlyModel.append({
                                time: i === 0 ? "Now" : t.toLocaleTimeString([], {hour: '2-digit', minute:'2-digit', hour12: false}),
                                icon: getFaIconFromAccu(it.WeatherIcon, it.IsDaylight),
                                temp: Math.round(it.Temperature.Value),
                                precip: it.TotalLiquid ? Number(it.TotalLiquid.Value).toFixed(1) : "0.0",
                                wind: Math.round(it.Wind.Speed.Value),
                                aqi: 20
                            });
                        }
                        refreshAllCanvases();
                    }
                }
                xhrHourly.send();
            }
        }
        xhrGeo.send();
    }

    function fetchAqiData(lat, lon) {
        var url = "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=" + lat + "&longitude=" + lon + 
                  "&current=us_aqi&hourly=us_aqi&timezone=auto";
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var aqiData = JSON.parse(xhr.responseText);
                    var realAqi = Math.round(aqiData.current.us_aqi);
                    weatherRoot.aqi = realAqi;
                    weatherRoot.aqiDesc = getAqiDesc(realAqi);
                    
                    let now = new Date();
                    let currentHourIdx = 0;
                    for (let i = 0; i < aqiData.hourly.time.length; i++) {
                        if (new Date(aqiData.hourly.time[i]) >= now) { currentHourIdx = i > 0 ? i - 1 : 0; break; }
                    }

                    for (let i = 0; i < hourlyModel.count; i++) {
                        let hIdx = currentHourIdx + i;
                        if (hIdx < aqiData.hourly.us_aqi.length) {
                            hourlyModel.setProperty(i, "aqi", Math.round(aqiData.hourly.us_aqi[hIdx]));
                        }
                    }
                    
                    let updatedDaily = weatherRoot.dailyWeather.slice();
                    for (let i = 0; i < updatedDaily.length; i++) {
                        let dIdx = Math.min(i * 24 + 12, aqiData.hourly.us_aqi.length - 1);
                        updatedDaily[i].aqi = Math.round(aqiData.hourly.us_aqi[dIdx]);
                    }
                    weatherRoot.dailyWeather = updatedDaily;
                    refreshAllCanvases();
                } catch(e) {
                    console.log("AQI Error: " + e);
                }
            }
        }
        xhr.send();
    }

    function fetchGeocoding(query) {
        var url = "https://geocoding-api.open-meteo.com/v1/search?name=" + encodeURIComponent(query) + "&count=25&language=en&format=json";
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var data = JSON.parse(xhr.responseText);
                var results = data.results || [];
                var newCities = [];
                for (var i = 0; i < results.length; i++) {
                    newCities.push({
                        name: results[i].name,
                        country: results[i].country + (results[i].admin1 ? ", " + results[i].admin1 : ""),
                        lat: results[i].latitude,
                        lon: results[i].longitude,
                        isAuto: false
                    });
                }
                weatherRoot.filteredCities = newCities.length > 0 ? newCities : weatherRoot.comprehensiveCities;
            }
        }
        xhr.send();
    }

    Timer {
        id: searchDebounce
        interval: 350
        onTriggered: {
            if (weatherRoot.locationSearchQuery.trim().length > 1) {
                weatherRoot.fetchGeocoding(weatherRoot.locationSearchQuery);
            } else {
                weatherRoot.filteredCities = weatherRoot.comprehensiveCities;
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Metrics.spacingBase
        anchors.margins: Metrics.spacingBase

        // ==========================================
        // HEADER ROW: TITLE & CONTROLS
        // ==========================================
        RowLayout {
            Layout.fillWidth: true
            z: 100 

            Text {
                text: "Weather & Environment"
                color: Theme.main
                font.family: Theme.fontMain
                font.pixelSize: 18
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true }

            // --- 1. DATA SOURCE PICKER ---
            Item {
                width: 170
                height: 36
                z: 101 

                Rectangle {
                    id: sourceBtn
                    anchors.fill: parent
                    color: sourceMouse.containsMouse ? Qt.darker(Theme.base, 1.2) : Qt.darker(Theme.base, 1.4)
                    radius: 18
                    border.color: weatherRoot.isSourcePickerOpen ? Theme.main : Theme.bridge
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "\uf1c0" 
                            color: Theme.secondary
                            font.family: Theme.fontIcon
                            font.pixelSize: 14
                        }
                        Text {
                            text: weatherRoot.currentSource
                            color: Theme.text
                            font.family: Theme.fontMain
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            text: weatherRoot.isSourcePickerOpen ? "\uf106" : "\uf107" 
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                            font.family: Theme.fontIcon
                            font.pixelSize: 14
                        }
                    }

                    MouseArea {
                        id: sourceMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            weatherRoot.isSourcePickerOpen = !weatherRoot.isSourcePickerOpen;
                            if (weatherRoot.isSourcePickerOpen) weatherRoot.isLocationPickerOpen = false;
                        }
                    }
                }

                Rectangle {
                    id: sourceDropdownPopup
                    anchors.top: sourceBtn.bottom
                    anchors.topMargin: 8
                    anchors.right: sourceBtn.right
                    width: 200
                    height: (sourceDatabase.length * 36) + 16
                    color: Qt.darker(Theme.base, 1.1)
                    radius: Metrics.radiusBase
                    border.color: Theme.bridge
                    border.width: 1
                    visible: weatherRoot.isSourcePickerOpen
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 0

                        Repeater {
                            model: weatherRoot.sourceDatabase
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 36
                                radius: 8
                                color: sourceItemHover.containsMouse ? Qt.darker(Theme.base, 1.3) : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    Text {
                                        text: modelData.icon
                                        color: Theme.secondary
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 13
                                    }
                                    Text {
                                        text: modelData.name
                                        color: Theme.text
                                        font.family: Theme.fontMain
                                        font.pixelSize: 14
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                    Text {
                                        text: "\uf00c" 
                                        color: Theme.main
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 12
                                        visible: weatherRoot.currentSource === modelData.name
                                    }
                                }

                                MouseArea {
                                    id: sourceItemHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        weatherRoot.currentSource = modelData.name;
                                        weatherRoot.saveWeatherSettings();
                                        weatherRoot.isSourcePickerOpen = false;
                                        weatherRoot.fetchWeatherData(weatherRoot.currentLat, weatherRoot.currentLon);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --- 2. LOCATION SEARCH PICKER ---
            Item {
                width: 260
                height: 36
                z: 100 

                Rectangle {
                    id: locationBtn
                    anchors.fill: parent
                    color: locationMouse.containsMouse ? Qt.darker(Theme.base, 1.2) : Qt.darker(Theme.base, 1.4)
                    radius: 18
                    border.color: weatherRoot.isLocationPickerOpen ? Theme.main : Theme.bridge
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: "\uf3c5" 
                            color: Theme.main
                            font.family: Theme.fontIcon
                            font.pixelSize: 14
                        }
                        Text {
                            text: weatherRoot.currentLocation
                            color: Theme.text
                            font.family: Theme.fontMain
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        Text {
                            text: weatherRoot.isLocationPickerOpen ? "\uf106" : "\uf107" 
                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                            font.family: Theme.fontIcon
                            font.pixelSize: 14
                        }
                    }

                    MouseArea {
                        id: locationMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: {
                            weatherRoot.isLocationPickerOpen = !weatherRoot.isLocationPickerOpen;
                            if (weatherRoot.isLocationPickerOpen) {
                                weatherRoot.isSourcePickerOpen = false;
                                citySearchInput.forceActiveFocus();
                            }
                        }
                    }
                }

                Rectangle {
                    id: dropdownPopup
                    anchors.top: locationBtn.bottom
                    anchors.topMargin: 8
                    anchors.right: locationBtn.right
                    width: 300
                    height: 280
                    color: Qt.darker(Theme.base, 1.1)
                    radius: Metrics.radiusBase
                    border.color: Theme.bridge
                    border.width: 1
                    visible: weatherRoot.isLocationPickerOpen
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            color: Qt.darker(Theme.base, 1.4)
                            radius: 18
                            border.color: citySearchInput.activeFocus ? Theme.main : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                Text {
                                    text: "\uf002" 
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5)
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 13
                                }

                                TextField {
                                    id: citySearchInput
                                    Layout.fillWidth: true
                                    placeholderText: "Search any city..."
                                    font.family: Theme.fontMain
                                    font.pixelSize: 14
                                    color: Theme.text
                                    background: null
                                    onTextChanged: {
                                        weatherRoot.locationSearchQuery = text;
                                        searchDebounce.restart();
                                    }
                                }
                            }
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            model: weatherRoot.filteredCities
                            ScrollBar.vertical: ScrollBar { active: true; policy: ScrollBar.AsNeeded }

                            delegate: Rectangle {
                                width: parent.width
                                height: 38
                                radius: 8
                                color: itemHover.containsMouse ? Qt.darker(Theme.base, 1.3) : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    Text {
                                        text: modelData.isAuto ? "\uf3c5" : "\uf0ac"
                                        color: Theme.main
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 13
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0
                                        Text {
                                            text: modelData.name
                                            color: Theme.text
                                            font.family: Theme.fontMain
                                            font.pixelSize: 13
                                            font.weight: Font.Bold
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: modelData.country
                                            color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                            font.family: Theme.fontMain
                                            font.pixelSize: 11
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                MouseArea {
                                    id: itemHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        weatherRoot.currentLocation = modelData.name + (modelData.isAuto ? "" : ", " + modelData.country);
                                        weatherRoot.currentLat = modelData.lat;
                                        weatherRoot.currentLon = modelData.lon;
                                        weatherRoot.saveWeatherSettings();
                                        weatherRoot.isLocationPickerOpen = false;
                                        weatherRoot.fetchWeatherData(modelData.lat, modelData.lon);
                                        weatherRoot.locationSearchQuery = "";
                                        citySearchInput.text = "";
                                        weatherRoot.filteredCities = weatherRoot.comprehensiveCities;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // --- 3. UNIT TOGGLE ---
            Rectangle {
                width: 60
                height: 36
                color: unitMouse.containsMouse ? Qt.darker(Theme.base, 1.2) : Qt.darker(Theme.base, 1.4)
                radius: 18
                border.color: Theme.bridge
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: weatherRoot.isFahrenheit ? "°F" : "°C"
                    color: Theme.text
                    font.family: Theme.fontMain
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }

                MouseArea {
                    id: unitMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        weatherRoot.isFahrenheit = !weatherRoot.isFahrenheit;
                        weatherRoot.saveWeatherSettings();
                        weatherRoot.refreshAllCanvases();
                    }
                }
            }
        }

        // ==========================================
        // MAIN STRICT 2-COLUMN DASHBOARD
        // ==========================================
        Flickable {
            id: scrollArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: mainContent.implicitHeight + Metrics.spacingLarge
            contentWidth: width 
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            interactive: contentHeight > height

            RowLayout {
                id: mainContent
                width: scrollArea.width 
                spacing: Metrics.spacingLarge
                anchors.top: parent.top

                // ------------------------------------------
                // LEFT COLUMN
                // ------------------------------------------
                ColumnLayout {
                    Layout.preferredWidth: parent.width / 2 - (Metrics.spacingLarge / 2)
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: Metrics.spacingLarge

                    // Main Temperature Card (Goldilocks Size & Seamless Hover)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 145 
                        color: "transparent"
                        radius: Metrics.radiusBase
                        border.width: mainHover.hovered ? 1 : 0
                        border.color: mainHover.hovered ? Theme.main : "transparent"
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        HoverHandler { id: mainHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Metrics.spacingLarge
                            spacing: Metrics.spacingBase

                            ColumnLayout {
                                Layout.alignment: Qt.AlignVCenter
                                spacing: -4

                                RowLayout {
                                    spacing: 12
                                    Text {
                                        text: weatherRoot.weatherIcon
                                        color: Theme.main
                                        font.family: Theme.fontIcon
                                        font.pixelSize: 64 
                                    }
                                    Text {
                                        text: weatherRoot.getTemp(weatherRoot.currentTemp) + "°"
                                        color: Theme.text
                                        font.family: Theme.fontMain
                                        font.pixelSize: 68
                                        font.weight: Font.Bold
                                    }
                                }
                                Text {
                                    text: weatherRoot.weatherDesc
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                                    font.family: Theme.fontMain
                                    font.pixelSize: 20
                                    font.weight: Font.Medium
                                    Layout.leftMargin: 5
                                }
                            }

                            Item { Layout.fillWidth: true }

                            ColumnLayout {
                                Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                                spacing: 8

                                Text {
                                    text: "Feels: " + weatherRoot.getTemp(weatherRoot.feelsLike) + "°"
                                    color: Theme.text
                                    font.family: Theme.fontMain
                                    font.pixelSize: 20
                                    font.weight: Font.Bold
                                    Layout.alignment: Qt.AlignRight
                                }
                                Text {
                                    text: "Day: " + weatherRoot.getTemp(weatherRoot.dayTemp) + "°"
                                    color: Theme.main
                                    font.family: Theme.fontMain
                                    font.pixelSize: 18
                                    font.weight: Font.Medium
                                    Layout.alignment: Qt.AlignRight
                                }
                                Text {
                                    text: "Night: " + weatherRoot.getTemp(weatherRoot.nightTemp) + "°"
                                    color: Theme.secondary
                                    font.family: Theme.fontMain
                                    font.pixelSize: 18
                                    font.weight: Font.Medium
                                    Layout.alignment: Qt.AlignRight
                                }
                            }
                        }
                    }

                    // Dual Celestial Arcs (Seamless Hover)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 130
                        color: "transparent"
                        radius: Metrics.radiusBase
                        border.width: arcHover.hovered ? 1 : 0
                        border.color: arcHover.hovered ? Theme.main : "transparent"
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        HoverHandler { id: arcHover }
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Metrics.spacingLarge
                            spacing: 0

                            Text {
                                text: "Sun & Moon Cycle"
                                color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                font.family: Theme.fontMain
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                Layout.bottomMargin: 8
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 15

                                // --- SUN ARC (Secondary Color) ---
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 4

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        Canvas {
                                            id: sunCanvas
                                            anchors.fill: parent

                                            onPaint: {
                                                var ctx = getContext("2d");
                                                ctx.clearRect(0, 0, width, height);

                                                var centerX = width / 2;
                                                var centerY = height - 4;
                                                var radius = Math.min(centerX, height) - 10;

                                                ctx.beginPath();
                                                ctx.arc(centerX, centerY, radius, Math.PI, 2 * Math.PI);
                                                ctx.strokeStyle = Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.5).toString();
                                                ctx.lineWidth = 1.5;
                                                ctx.setLineDash([3, 5]);
                                                ctx.stroke();

                                                let prog = weatherRoot.sunProgress;
                                                let currentAngle = Math.PI + (Math.PI * prog);
                                                ctx.beginPath();
                                                ctx.arc(centerX, centerY, radius, Math.PI, currentAngle);
                                                ctx.strokeStyle = Theme.secondary.toString(); 
                                                ctx.setLineDash([]);
                                                ctx.lineWidth = 2.5;
                                                ctx.stroke();
                                            }
                                        }

                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 12
                                            color: Theme.secondary

                                            readonly property real cx: parent.width / 2
                                            readonly property real cy: parent.height - 4
                                            readonly property real rad: Math.min(cx, parent.height) - 10
                                            readonly property real ang: Math.PI + (Math.PI * weatherRoot.sunProgress)

                                            x: cx + rad * Math.cos(ang) - width / 2
                                            y: cy + rad * Math.sin(ang) - height / 2

                                            Text {
                                                anchors.centerIn: parent
                                                text: "\uf185"
                                                color: Theme.base
                                                font.family: Theme.fontIcon
                                                font.pixelSize: 13
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "\uf185 " + weatherRoot.sunriseTime; color: Theme.secondary; font.family: Theme.fontMain; font.pixelSize: 14 }
                                        Item { Layout.fillWidth: true }
                                        Text { text: weatherRoot.sunsetTime + " \uf185"; color: Theme.secondary; font.family: Theme.fontMain; font.pixelSize: 14 }
                                    }
                                }

                                Rectangle {
                                    Layout.fillHeight: true
                                    width: 1
                                    color: Qt.darker(Theme.base, 1.4)
                                }

                                // --- MOON ARC (Main Color) ---
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 4

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true

                                        Canvas {
                                            id: moonCanvas
                                            anchors.fill: parent

                                            onPaint: {
                                                var ctx = getContext("2d");
                                                ctx.clearRect(0, 0, width, height);

                                                var centerX = width / 2;
                                                var centerY = height - 4;
                                                var radius = Math.min(centerX, height) - 10;

                                                ctx.beginPath();
                                                ctx.arc(centerX, centerY, radius, Math.PI, 2 * Math.PI);
                                                ctx.strokeStyle = Qt.rgba(Theme.bridge.r, Theme.bridge.g, Theme.bridge.b, 0.5).toString();
                                                ctx.lineWidth = 1.5;
                                                ctx.setLineDash([3, 5]);
                                                ctx.stroke();

                                                let prog = weatherRoot.moonProgress;
                                                let currentAngle = Math.PI + (Math.PI * prog);
                                                ctx.beginPath();
                                                ctx.arc(centerX, centerY, radius, Math.PI, currentAngle);
                                                ctx.strokeStyle = Theme.main.toString();
                                                ctx.setLineDash([]);
                                                ctx.lineWidth = 2.5;
                                                ctx.stroke();
                                            }
                                        }

                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 12
                                            color: Theme.main

                                            readonly property real cx: parent.width / 2
                                            readonly property real cy: parent.height - 4
                                            readonly property real rad: Math.min(cx, parent.height) - 10
                                            readonly property real ang: Math.PI + (Math.PI * weatherRoot.moonProgress)

                                            x: cx + rad * Math.cos(ang) - width / 2
                                            y: cy + rad * Math.sin(ang) - height / 2

                                            Text {
                                                anchors.centerIn: parent
                                                text: "\uf186"
                                                color: Theme.base
                                                font.family: Theme.fontIcon
                                                font.pixelSize: 13
                                            }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        Text { text: "\uf186 " + weatherRoot.moonriseTime; color: Theme.main; font.family: Theme.fontMain; font.pixelSize: 14 }
                                        Item { Layout.fillWidth: true }
                                        Text { text: weatherRoot.moonPhase; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5); font.family: Theme.fontMain; font.pixelSize: 12 }
                                        Item { Layout.fillWidth: true }
                                        Text { text: weatherRoot.moonsetTime + " \uf186"; color: Theme.main; font.family: Theme.fontMain; font.pixelSize: 14 }
                                    }
                                }
                            }
                        }
                    }

                    // Today's Forecast Meteogram (Seamless Hover)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 260 
                        color: "transparent"
                        radius: Metrics.radiusBase
                        border.width: todayHover.hovered ? 1 : 0
                        border.color: todayHover.hovered ? Theme.main : "transparent"
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        HoverHandler { id: todayHover }
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Metrics.spacingLarge
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "Today's Forecast"
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                    font.family: Theme.fontMain
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    Layout.fillWidth: true
                                }

                                RowLayout {
                                    spacing: 6
                                    Repeater {
                                        model: ["Weather", "Precip", "AQI", "Wind"]
                                        delegate: Rectangle {
                                            width: tabTextHourly.implicitWidth + 16
                                            height: 28
                                            radius: 14
                                            color: weatherRoot.hourlyActiveTab === index ? Theme.main : Qt.darker(Theme.base, 1.5)
                                            z: 10

                                            Text {
                                                id: tabTextHourly
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: weatherRoot.hourlyActiveTab === index ? Theme.base : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                                                font.family: Theme.fontMain
                                                font.pixelSize: 13
                                                font.weight: Font.Bold
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                preventStealing: true
                                                onClicked: {
                                                    weatherRoot.hourlyActiveTab = index;
                                                    weatherRoot.refreshAllCanvases();
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Hourly Weather Tab
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: weatherRoot.hourlyActiveTab === 0
                                spacing: 0

                                Row {
                                    Layout.fillWidth: true
                                    height: 50
                                    Repeater {
                                        model: hourlyModel
                                        Item {
                                            width: parent.width / hourlyModel.count
                                            height: parent.height
                                            ColumnLayout {
                                                anchors.centerIn: parent
                                                spacing: 4
                                                Text { text: model.time; color: index === 0 ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.8); font.family: Theme.fontMain; font.pixelSize: 14; font.weight: index === 0 ? Font.Bold : Font.Normal; Layout.alignment: Qt.AlignHCenter }
                                                Text { text: model.icon; color: Theme.main; font.family: Theme.fontIcon; font.pixelSize: 22; Layout.alignment: Qt.AlignHCenter }
                                            }
                                        }
                                    }
                                }

                                Canvas {
                                    id: hourlyWeatherCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        let count = hourlyModel.count;
                                        if (count === 0) return;

                                        let temps = [];
                                        for (let i = 0; i < count; i++) {
                                            temps.push(weatherRoot.getTemp(hourlyModel.get(i).temp));
                                        }

                                        let maxT = Math.max.apply(null, temps);
                                        let minT = Math.min.apply(null, temps);
                                        let range = maxT - minT; if (range === 0) range = 1;
                                        let step = width / count;

                                        // THE FIX: Enforce a hard 35px padding top and bottom so text never clips
                                        let padTop = 35;
                                        let padBot = 35;

                                        let pts = [];
                                        for (let i = 0; i < count; i++) {
                                            let x = (i * step) + (step / 2);
                                            // Scale Y strictly between the padding zones
                                            let y = height - (((temps[i] - minT) / range) * height);
                                            let paddedY = padTop + (y * ((height - (padTop + padBot)) / height));
                                            pts.push({ x: x, temp: temps[i], y: paddedY });
                                        }

                                        var gradient = ctx.createLinearGradient(0, 0, 0, height);
                                        gradient.addColorStop(0, Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.25).toString());
                                        gradient.addColorStop(1, Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.0).toString());
                                        ctx.beginPath();
                                        for (let i = 0; i < count; i++) {
                                            if (i === 0) ctx.moveTo(pts[i].x, pts[i].y); else ctx.lineTo(pts[i].x, pts[i].y);
                                        }
                                        ctx.lineTo(pts[count - 1].x, height); ctx.lineTo(pts[0].x, height);
                                        ctx.closePath(); ctx.fillStyle = gradient; ctx.fill();

                                        ctx.beginPath(); ctx.lineWidth = 3; ctx.strokeStyle = Theme.main.toString();
                                        for (let i = 0; i < count; i++) {
                                            if (i === 0) ctx.moveTo(pts[i].x, pts[i].y); else ctx.lineTo(pts[i].x, pts[i].y);
                                        }
                                        ctx.stroke();

                                        ctx.fillStyle = Theme.text.toString(); ctx.font = "bold 16px sans-serif"; ctx.textAlign = "center";
                                        for (let i = 0; i < count; i++) {
                                            // The 35px padding safely absorbs this -12 offset
                                            ctx.fillText(pts[i].temp + "°", pts[i].x, pts[i].y - 12);
                                        }
                                    }
                                }
                            }

                            // Hourly Precip Tab
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: weatherRoot.hourlyActiveTab === 1
                                spacing: 0

                                Row {
                                    Layout.fillWidth: true
                                    height: 40
                                    Repeater {
                                        model: hourlyModel
                                        Item {
                                            width: parent.width / hourlyModel.count
                                            height: parent.height
                                            Text { anchors.centerIn: parent; text: model.time; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 14; font.weight: Font.Bold }
                                        }
                                    }
                                }

                                Canvas {
                                    id: hourlyPrecipCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        let count = hourlyModel.count;
                                        if (count === 0) return;
                                        let step = width / count;

                                        for (let i = 0; i < count; i++) {
                                            let val = parseFloat(hourlyModel.get(i).precip);
                                            let barH = (val / 5.0) * (height - 30);
                                            let x = (i * step) + (step / 2) - 15;
                                            let y = height - barH - 25;

                                            ctx.fillStyle = Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.3).toString();
                                            ctx.fillRect(x, 15, 30, height - 40);
                                            ctx.fillStyle = Theme.secondary.toString();
                                            ctx.fillRect(x, y, 30, barH);
                                            ctx.fillStyle = Theme.text.toString(); ctx.font = "14px sans-serif"; ctx.textAlign = "center";
                                            ctx.fillText(hourlyModel.get(i).precip, x + 15, height - 5);
                                        }
                                    }
                                }
                            }

                            // Hourly AQI Tab
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: weatherRoot.hourlyActiveTab === 2
                                spacing: 0

                                Row {
                                    Layout.fillWidth: true
                                    height: 40
                                    Repeater {
                                        model: hourlyModel
                                        Item {
                                            width: parent.width / hourlyModel.count
                                            height: parent.height
                                            Text { anchors.centerIn: parent; text: model.time; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 14; font.weight: Font.Bold }
                                        }
                                    }
                                }

                                Canvas {
                                    id: hourlyAqiCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        let count = hourlyModel.count;
                                        if (count === 0) return;
                                        let step = width / count;

                                        let pts = [];
                                        for (let i = 0; i < count; i++) {
                                            let aqiVal = hourlyModel.get(i).aqi;
                                            let x = (i * step) + (step / 2);
                                            let y = height - ((aqiVal / 100.0) * (height - 40)) - 20;
                                            pts.push({ x: x, val: aqiVal, y: y });
                                        }

                                        ctx.beginPath(); ctx.lineWidth = 3; ctx.strokeStyle = Theme.main.toString();
                                        for (let i = 0; i < pts.length; i++) {
                                            if (i === 0) ctx.moveTo(pts[i].x, pts[i].y); else ctx.lineTo(pts[i].x, pts[i].y);
                                        }
                                        ctx.stroke();

                                        for (let i = 0; i < pts.length; i++) {
                                            ctx.beginPath(); ctx.arc(pts[i].x, pts[i].y, 6, 0, 2 * Math.PI);
                                            ctx.fillStyle = Theme.main.toString(); ctx.fill();
                                            ctx.fillStyle = Theme.text.toString(); ctx.font = "bold 13px sans-serif"; ctx.textAlign = "center";
                                            ctx.fillText("AQI " + pts[i].val, pts[i].x, pts[i].y - 12);
                                        }
                                    }
                                }
                            }

                            // Hourly Wind Tab
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: weatherRoot.hourlyActiveTab === 3
                                spacing: 0

                                Row {
                                    Layout.fillWidth: true
                                    height: 40
                                    Repeater {
                                        model: hourlyModel
                                        Item {
                                            width: parent.width / hourlyModel.count
                                            height: parent.height
                                            Text { anchors.centerIn: parent; text: model.time; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 14; font.weight: Font.Bold }
                                        }
                                    }
                                }

                                Canvas {
                                    id: hourlyWindCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        let count = hourlyModel.count;
                                        if (count === 0) return;
                                        let step = width / count;

                                        let pts = [];
                                        for (let i = 0; i < count; i++) {
                                            let speedNum = parseInt(hourlyModel.get(i).wind);
                                            let x = (i * step) + (step / 2);
                                            let y = height - ((speedNum / 30.0) * (height - 40)) - 20;
                                            pts.push({ x: x, val: hourlyModel.get(i).wind, y: y });
                                        }

                                        ctx.beginPath(); ctx.lineWidth = 3; ctx.strokeStyle = Theme.secondary.toString();
                                        for (let i = 0; i < pts.length; i++) {
                                            if (i === 0) ctx.moveTo(pts[i].x, pts[i].y); else ctx.lineTo(pts[i].x, pts[i].y);
                                        }
                                        ctx.stroke();

                                        for (let i = 0; i < pts.length; i++) {
                                            ctx.beginPath(); ctx.arc(pts[i].x, pts[i].y, 6, 0, 2 * Math.PI);
                                            ctx.fillStyle = Theme.secondary.toString(); ctx.fill();
                                            ctx.fillStyle = Theme.text.toString(); ctx.font = "bold 13px sans-serif"; ctx.textAlign = "center";
                                            ctx.fillText(pts[i].val, pts[i].x, pts[i].y - 12);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ------------------------------------------
                // RIGHT COLUMN
                // ------------------------------------------
                ColumnLayout {
                    Layout.preferredWidth: parent.width / 2 - (Metrics.spacingLarge / 2)
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: Metrics.spacingLarge

                    // Top-Right: 4 Mini Widgets (Transparent styling with hover borders)
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 290 // Matches the newly adjusted layout height
                        columns: 2
                        columnSpacing: Metrics.spacingLarge
                        rowSpacing: Metrics.spacingLarge

                        // Precip
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"
                            radius: Metrics.radiusBase
                            border.width: hHover1.hovered ? 1 : 0
                            border.color: hHover1.hovered ? Theme.main : "transparent"
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            HoverHandler { id: hHover1 }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "\uf04e"; color: Theme.secondary; font.family: Theme.fontIcon; font.pixelSize: 42; Layout.alignment: Qt.AlignHCenter }
                                Text { text: weatherRoot.precipChance; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 32; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
                                Text { text: weatherRoot.precipVolume; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 18; Layout.alignment: Qt.AlignHCenter }
                            }
                        }

                        // Wind
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"
                            radius: Metrics.radiusBase
                            border.width: hHover2.hovered ? 1 : 0
                            border.color: hHover2.hovered ? Theme.main : "transparent"
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            HoverHandler { id: hHover2 }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text {
                                    text: "\uf124"
                                    color: Theme.main
                                    font.family: Theme.fontIcon
                                    font.pixelSize: 42
                                    rotation: weatherRoot.windDirection - 45
                                    Behavior on rotation { NumberAnimation { duration: 500 } }
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text { text: weatherRoot.windSpeed; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 32; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
                                Text { text: "Dir: " + weatherRoot.windDirection + "°"; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 18; Layout.alignment: Qt.AlignHCenter }
                            }
                        }

                        // AQI
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"
                            radius: Metrics.radiusBase
                            border.width: hHover3.hovered ? 1 : 0
                            border.color: hHover3.hovered ? Theme.main : "transparent"
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            HoverHandler { id: hHover3 }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "\uf06c"; color: Theme.main; font.family: Theme.fontIcon; font.pixelSize: 42; Layout.alignment: Qt.AlignHCenter }
                                Text { text: "AQI " + weatherRoot.aqi; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 32; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
                                Text { text: weatherRoot.aqiDesc; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 18; Layout.alignment: Qt.AlignHCenter }
                            }
                        }

                        // Humidity
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"
                            radius: Metrics.radiusBase
                            border.width: hHover4.hovered ? 1 : 0
                            border.color: hHover4.hovered ? Theme.main : "transparent"
                            Behavior on border.color { ColorAnimation { duration: 150 } }
                            HoverHandler { id: hHover4 }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "\uf043"; color: Theme.secondary; font.family: Theme.fontIcon; font.pixelSize: 42; Layout.alignment: Qt.AlignHCenter }
                                Text { text: weatherRoot.humidity; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 32; font.weight: Font.Bold; Layout.alignment: Qt.AlignHCenter }
                                Text { text: "Dew: " + weatherRoot.getTemp(weatherRoot.dewPoint) + (weatherRoot.isFahrenheit ? "°F" : "°C"); color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6); font.family: Theme.fontMain; font.pixelSize: 18; Layout.alignment: Qt.AlignHCenter }
                            }
                        }
                    }

                    // 7-Day Outlook Meteogram (Seamless Hover)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 260 
                        color: "transparent"
                        radius: Metrics.radiusBase
                        border.width: weekHover.hovered ? 1 : 0
                        border.color: weekHover.hovered ? Theme.main : "transparent"
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        HoverHandler { id: weekHover }
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: Metrics.spacingLarge
                            spacing: 8

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: "7-Day Outlook"
                                    color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.6)
                                    font.family: Theme.fontMain
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    Layout.fillWidth: true
                                }

                                RowLayout {
                                    spacing: 6
                                    Repeater {
                                        model: ["Weather", "Precip", "AQI", "Wind"]
                                        delegate: Rectangle {
                                            width: tabText.implicitWidth + 16
                                            height: 28
                                            radius: 14
                                            color: weatherRoot.activeTab === index ? Theme.main : Qt.darker(Theme.base, 1.5)
                                            z: 10

                                            Text {
                                                id: tabText
                                                anchors.centerIn: parent
                                                text: modelData
                                                color: weatherRoot.activeTab === index ? Theme.base : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7)
                                                font.family: Theme.fontMain
                                                font.pixelSize: 13
                                                font.weight: Font.Bold
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                preventStealing: true
                                                onClicked: {
                                                    weatherRoot.activeTab = index;
                                                    weatherRoot.refreshAllCanvases();
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // 7-Day Weather Tab
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: weatherRoot.activeTab === 0
                                spacing: 0

                                Row {
                                    Layout.fillWidth: true
                                    height: 50
                                    Repeater {
                                        model: weatherRoot.dailyWeather
                                        Item {
                                            width: parent.width / 7
                                            height: parent.height
                                            ColumnLayout {
                                                anchors.centerIn: parent
                                                spacing: 2
                                                Text { text: modelData.day; color: modelData.day === "Today" ? Theme.text : Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.8); font.family: Theme.fontMain; font.pixelSize: 14; font.weight: modelData.day === "Today" ? Font.Bold : Font.Normal; Layout.alignment: Qt.AlignHCenter }
                                                Text { text: modelData.date; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.5); font.family: Theme.fontMain; font.pixelSize: 12; Layout.alignment: Qt.AlignHCenter }
                                                Text { text: modelData.dayIcon; color: Theme.main; font.family: Theme.fontIcon; font.pixelSize: 18; Layout.alignment: Qt.AlignHCenter }
                                            }
                                        }
                                    }
                                }

                                Canvas {
                                    id: weatherCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        let items = weatherRoot.dailyWeather;
                                        let len = items.length;
                                        if (len === 0) return;

                                        let highs = [];
                                        let lows = [];
                                        
                                        for (let i = 0; i < len; i++) {
                                            highs.push(weatherRoot.getTemp(items[i].high));
                                            lows.push(weatherRoot.getTemp(items[i].low));
                                        }

                                        let maxT = Math.max.apply(null, highs);
                                        let minT = Math.min.apply(null, lows);
                                        let range = maxT - minT; if (range === 0) range = 1;
                                        let step = width / len;

                                        // THE FIX: Hard 35px padding top and bottom
                                        let padTop = 35;
                                        let padBot = 35;

                                        let pts = [];
                                        for (let i = 0; i < len; i++) {
                                            let x = (i * step) + (step / 2);
                                            let y1 = height - (((highs[i] - minT) / range) * height);
                                            let y2 = height - (((lows[i] - minT) / range) * height);
                                            let paddedY1 = padTop + (y1 * ((height - (padTop + padBot)) / height));
                                            let paddedY2 = padTop + (y2 * ((height - (padTop + padBot)) / height));
                                            pts.push({ x: x, high: highs[i], low: lows[i], highY: paddedY1, lowY: paddedY2 });
                                        }

                                        var gradient = ctx.createLinearGradient(0, 0, 0, height);
                                        gradient.addColorStop(0, Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.25).toString());
                                        gradient.addColorStop(1, Qt.rgba(Theme.main.r, Theme.main.g, Theme.main.b, 0.0).toString());
                                        ctx.beginPath();
                                        for (let i = 0; i < len; i++) { if (i === 0) ctx.moveTo(pts[i].x, pts[i].highY); else ctx.lineTo(pts[i].x, pts[i].highY); }
                                        for (let i = len - 1; i >= 0; i--) { ctx.lineTo(pts[i].x, pts[i].lowY); }
                                        ctx.closePath(); ctx.fillStyle = gradient; ctx.fill();

                                        ctx.beginPath(); ctx.lineWidth = 3; ctx.strokeStyle = Theme.main.toString();
                                        for (let i = 0; i < len; i++) { if (i === 0) ctx.moveTo(pts[i].x, pts[i].highY); else ctx.lineTo(pts[i].x, pts[i].highY); }
                                        ctx.stroke();

                                        ctx.beginPath(); ctx.lineWidth = 3; ctx.strokeStyle = Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.6).toString();
                                        for (let i = 0; i < len; i++) { if (i === 0) ctx.moveTo(pts[i].x, pts[i].lowY); else ctx.lineTo(pts[i].x, pts[i].lowY); }
                                        ctx.stroke();

                                        ctx.fillStyle = Theme.text.toString(); ctx.font = "bold 16px sans-serif"; ctx.textAlign = "center";
                                        for (let i = 0; i < len; i++) {
                                            ctx.fillText(pts[i].high + "°", pts[i].x, pts[i].highY - 12);
                                            ctx.fillText(pts[i].low + "°", pts[i].x, pts[i].lowY + 24);
                                        }
                                    }
                                }

                                Row {
                                    Layout.fillWidth: true
                                    height: 25
                                    Repeater {
                                        model: weatherRoot.dailyWeather
                                        Item {
                                            width: parent.width / 7
                                            height: parent.height
                                            Text { anchors.centerIn: parent; text: modelData.nightIcon; color: Qt.rgba(Theme.text.r, Theme.text.g, Theme.text.b, 0.7); font.family: Theme.fontIcon; font.pixelSize: 16 }
                                        }
                                    }
                                }
                            }

                            // 7-Day Precip Tab
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: weatherRoot.activeTab === 1
                                spacing: 0

                                Row {
                                    Layout.fillWidth: true
                                    height: 40
                                    Repeater {
                                        model: weatherRoot.dailyWeather
                                        Item {
                                            width: parent.width / 7
                                            height: parent.height
                                            Text { anchors.centerIn: parent; text: modelData.day; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 14; font.weight: Font.Bold }
                                        }
                                    }
                                }

                                Canvas {
                                    id: precipCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        let items = weatherRoot.dailyWeather;
                                        if (items.length === 0) return;
                                        let step = width / items.length;

                                        for (let i = 0; i < items.length; i++) {
                                            let val = parseFloat(items[i].precip);
                                            let barH = (val / 10.0) * (height - 30);
                                            let x = (i * step) + (step / 2) - 15;
                                            let y = height - barH - 25;

                                            ctx.fillStyle = Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.3).toString();
                                            ctx.fillRect(x, 15, 30, height - 40);
                                            ctx.fillStyle = Theme.secondary.toString();
                                            ctx.fillRect(x, y, 30, barH);
                                            ctx.fillStyle = Theme.text.toString(); ctx.font = "14px sans-serif"; ctx.textAlign = "center";
                                            ctx.fillText(items[i].precip, x + 15, height - 5);
                                        }
                                    }
                                }
                            }

                            // 7-Day AQI Tab
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: weatherRoot.activeTab === 2
                                spacing: 0

                                Row {
                                    Layout.fillWidth: true
                                    height: 40
                                    Repeater {
                                        model: weatherRoot.dailyWeather
                                        Item {
                                            width: parent.width / 7
                                            height: parent.height
                                            Text { anchors.centerIn: parent; text: modelData.day; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 14; font.weight: Font.Bold }
                                        }
                                    }
                                }

                                Canvas {
                                    id: aqiCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        let items = weatherRoot.dailyWeather;
                                        if (items.length === 0) return;
                                        let step = width / items.length;

                                        let pts = [];
                                        for (let i = 0; i < items.length; i++) {
                                            let x = (i * step) + (step / 2);
                                            let y = height - ((items[i].aqi / 100.0) * (height - 40)) - 20;
                                            pts.push({ x: x, val: items[i].aqi, y: y });
                                        }

                                        ctx.beginPath(); ctx.lineWidth = 3; ctx.strokeStyle = Theme.main.toString();
                                        for (let i = 0; i < pts.length; i++) {
                                            if (i === 0) ctx.moveTo(pts[i].x, pts[i].y); else ctx.lineTo(pts[i].x, pts[i].y);
                                        }
                                        ctx.stroke();

                                        for (let i = 0; i < pts.length; i++) {
                                            ctx.beginPath(); ctx.arc(pts[i].x, pts[i].y, 6, 0, 2 * Math.PI);
                                            ctx.fillStyle = Theme.main.toString(); ctx.fill();
                                            ctx.fillStyle = Theme.text.toString(); ctx.font = "bold 13px sans-serif"; ctx.textAlign = "center";
                                            ctx.fillText("AQI " + pts[i].val, pts[i].x, pts[i].y - 12);
                                        }
                                    }
                                }
                            }

                            // 7-Day Wind Tab
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: weatherRoot.activeTab === 3
                                spacing: 0

                                Row {
                                    Layout.fillWidth: true
                                    height: 40
                                    Repeater {
                                        model: weatherRoot.dailyWeather
                                        Item {
                                            width: parent.width / 7
                                            height: parent.height
                                            Text { anchors.centerIn: parent; text: modelData.day; color: Theme.text; font.family: Theme.fontMain; font.pixelSize: 14; font.weight: Font.Bold }
                                        }
                                    }
                                }

                                Canvas {
                                    id: windCanvas
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    onPaint: {
                                        var ctx = getContext("2d");
                                        ctx.clearRect(0, 0, width, height);
                                        let items = weatherRoot.dailyWeather;
                                        if (items.length === 0) return;
                                        let step = width / items.length;

                                        let pts = [];
                                        for (let i = 0; i < items.length; i++) {
                                            let speedNum = parseInt(items[i].wind);
                                            let x = (i * step) + (step / 2);
                                            let y = height - ((speedNum / 30.0) * (height - 40)) - 20;
                                            pts.push({ x: x, val: items[i].wind, y: y });
                                        }

                                        ctx.beginPath(); ctx.lineWidth = 3; ctx.strokeStyle = Theme.secondary.toString();
                                        for (let i = 0; i < pts.length; i++) {
                                            if (i === 0) ctx.moveTo(pts[i].x, pts[i].y); else ctx.lineTo(pts[i].x, pts[i].y);
                                        }
                                        ctx.stroke();

                                        for (let i = 0; i < pts.length; i++) {
                                            ctx.beginPath(); ctx.arc(pts[i].x, pts[i].y, 6, 0, 2 * Math.PI);
                                            ctx.fillStyle = Theme.secondary.toString(); ctx.fill();
                                            ctx.fillStyle = Theme.text.toString(); ctx.font = "bold 13px sans-serif"; ctx.textAlign = "center";
                                            ctx.fillText(pts[i].val, pts[i].x, pts[i].y - 12);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
