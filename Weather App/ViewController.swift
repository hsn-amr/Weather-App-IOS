//
//  ViewController.swift
//  Weather App
//
//  Created by administrator on 23/12/2021.
//

import UIKit

class ViewController: UIViewController {

    
    @IBOutlet weak var icon: UIImageView!
    @IBOutlet weak var cityNameLabel: UILabel!
    @IBOutlet weak var descriptionWeatherLabel: UILabel!
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var windSpeedLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var cloudCoverLabel: UILabel!
    @IBOutlet weak var precipitationProbabilityLabel: UILabel!
    @IBOutlet weak var feelsLikeLabel: UILabel!
    
    @IBOutlet weak var tempsLabel: UILabel!
    
    @IBOutlet weak var hourlyCollectionView: UICollectionView!
    @IBOutlet weak var dailyCollectionView: UICollectionView!
    
    
    let zipCode = 10001
    let apiKey = "bffde61501b4f0bc542493cd91bd61b9"
   
    
    
    var currentWeather : CurrentWelcome?
    var hourlyArray = [List]()
    var dailyArray = [List]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        hourlyCollectionView.dataSource = self
        dailyCollectionView.dataSource = self
        
        self.requestCurrentWeatherApi(url: self.getCurrentWeatherApi(zipCode: self.zipCode, apiKey: self.apiKey))
        self.requestHourlyAndDailyWeatherApi(url: self.getHourlyAndDailyWeatherApi(zipCode: self.zipCode, apiKey: self.apiKey))
        
       
    }
    
    func getHourlyAndDailyWeatherApi(zipCode: Int, apiKey: String) -> String {
        return "http://api.openweathermap.org/data/2.5/forecast?zip=\(zipCode)&appid=\(apiKey)"
    }

    func getCurrentWeatherApi(zipCode: Int, apiKey: String) -> String {
        return "http://api.openweathermap.org/data/2.5/weather?zip=\(zipCode)&appid=\(apiKey)"
    }
    
    func getIconLink(icon: String)-> String{
        return "http://openweathermap.org/img/w/\(icon).png"
    }

    
    func requestCurrentWeatherApi(url: String){
        let url = URL(string: url)
        let session = URLSession.shared
        
        session.dataTask(with: url!, completionHandler: {
            data, response, error in
            
            guard let myData = data else {return}
            do {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                let reselt = try decoder.decode(CurrentWelcome.self, from: myData)
                self.currentWeather = reselt
                DispatchQueue.main.async {
                    self.updateUI()
                }
            } catch {
                print("fetching current weather error : \(error) - \(response)")
            }
        }).resume()
    }
    
    func requestHourlyAndDailyWeatherApi(url: String){
        let url = URL(string: url)
        let session = URLSession.shared
        
        session.dataTask(with: url!, completionHandler: {
            data, response, error in
            
            guard let myData = data else {return}
            do {
                let decoder = JSONDecoder()
                let result = try decoder.decode(Welcome.self, from: myData)
                for i in 0...6{
                    self.hourlyArray.append(result.list[i])
                }
                self.getDailyWeatherArray(result.list)
                DispatchQueue.main.async {
                    self.updateCollectionView()
                }
            } catch {
                print("fetching Hourly & Daily weather error : \(error) - \(response)")
            }
        }).resume()
    }
    
    func getDailyWeatherArray(_ hourlyArray: [List]){
        var today = fromDtToDate(dt: hourlyArray[0].dt, formatter: "EEEE")
        for daily in hourlyArray{
            let day = fromDtToDate(dt: daily.dt, formatter: "EEEE")
            if day != today{
                dailyArray.append(daily)
                today = day
            }
        }
    }
    
    func requestForIcon(url: String, setImage: @escaping (_ image: UIImage?) -> Void){
        let url = URL(string:  url)
        let session = URLSession.shared
        
        session.dataTask(with: url!, completionHandler: {
            data, response, error in
            
            guard let myData = data else {return}
          
            let image = UIImage(data: myData)
            setImage(image)
        }).resume()
    }
    
    func updateUI(){
        if let weather = currentWeather {
            let doubleFormat = "%.2f"
            let icon = weather.weather[0].icon
            requestForIcon(url: getIconLink(icon: icon), setImage: {
                image in
                DispatchQueue.main.async {
                    self.icon.image = image
                }
            })
            
            let name = weather.name
            let description = weather.weather[0].description
            let time = fromDtToDate(dt: weather.dt, formatter: "hh:mm a")
            let windSpeed = String(format: doubleFormat, weather.wind.speed)
            let humidity = String(weather.main.humidity)
            let cloudCover = String(weather.clouds.all)
            let feelsLike = String(format: doubleFormat, weather.main.feelsLike)
            let temp = String(Int(weather.main.temp))
            let minTemp = String(format: doubleFormat, weather.main.tempMin)
            let maxTemp = String(format: doubleFormat, weather.main.tempMax)
            cityNameLabel.text = "\(name) Weather"
            descriptionWeatherLabel.text = description
            
            timeLabel.text = "Time: \(time)"
            windSpeedLabel.text = "Wind Speed: \(windSpeed)MPH"
            humidityLabel.text = "Humidity: \(humidity)%"
            cloudCoverLabel.text = "Cloud Cover: \(cloudCover)%"
            
            feelsLikeLabel.text = "Feels Like: \(feelsLike)F"
            
            tempsLabel.text = "\(maxTemp)\n\(temp)\n\(minTemp)"
        }
    }
    
    func updateCollectionView(){
        hourlyCollectionView.reloadData()
        dailyCollectionView.reloadData()
        
        let pop = hourlyArray[0].pop * 100.0
        let precipitationProbability = String(format: "%.2f", pop)
        precipitationProbabilityLabel.text = "Precipitation Probability: \(precipitationProbability)%"
    }
    
    func fromDtToDate(dt: Double, formatter: String) -> String {
        let date = Date(timeIntervalSince1970: dt)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatter
        return dateFormatter.string(from: date)
    }
    // formatters
    /**
     Wednesday, Sep 12, 2018           --> EEEE, MMM d, yyyy
     09/12/2018                        --> MM/dd/yyyy
     09-12-2018 14:11                  --> MM-dd-yyyy HH:mm
     Sep 12, 2:11 PM                   --> MMM d, h:mm a
     September 2018                    --> MMMM yyyy
     Sep 12, 2018                      --> MMM d, yyyy
     Wed, 12 Sep 2018 14:11:54 +0000   --> E, d MMM yyyy HH:mm:ss Z
     2018-09-12T14:11:54+0000          --> yyyy-MM-dd'T'HH:mm:ssZ
     12.09.18                          --> dd.MM.yy
     10:41:02.112                      --> HH:mm:ss.SSS
     */
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout{
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.hourlyCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "hourCell", for: indexPath) as! HourCollectionViewCell
            
            let item = hourlyArray[indexPath.row]
            let time = fromDtToDate(dt: item.dt , formatter: "hh a")
            cell.hourCellLabel.text = time
            cell.tempCellLabel.text = "\(Int(item.main.temp))F"
            
            return cell
        }else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dayCell", for: indexPath) as! DayCollectionViewCell
            
            let item = dailyArray[indexPath.row]
            let day = fromDtToDate(dt: item.dt, formatter: "EEEE")
            let icon = item.weather[0].icon
            let temp = String(Int(item.main.temp))
            
            cell.dayCellDescription.text = day
            requestForIcon(url: getIconLink(icon: icon), setImage: {
                image in
                DispatchQueue.main.async {
                    cell.iconForDay.image = image
                }
            })
            cell.dayCellTemp.text = "\(temp)F"
            
            return cell
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.hourlyCollectionView {
            return hourlyArray.count
        }else {
            return dailyArray.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var size = CGSize()
        if collectionView == hourlyCollectionView{
            size = CGSize(width: collectionView.frame.width, height: collectionView.frame.height)
        }
        return size
    }
}
