//
//  ViewController.swift
//  WeatherSearcher
//
//  Created by Алина Власенко on 21.03.2023.
//

import UIKit
import RealmSwift

//Model for Realm
class WeatherData: Object {
    @Persisted var nameCity: String?
    @Persisted var descriptions: String?
    @Persisted var icons: String?
    @Persisted var temperatures: Float?
    @Persisted var pressures: Int?
    @Persisted var humidities: Int?
    @Persisted var feelsLike: Float?
    @Persisted var windSpeed: Float?
}

private enum Constants {
    static let temperature = " °C"
    static let pressure = "Pressure: "
    static let humidity = "Humidity: "
    static let windSpeed = "Wind speed: "
    static let feels = "fells like: "
}

class ViewController: UIViewController {
    
    var realm: Realm? //об'єкт Realm, який відповідає за збереження та читання даних
    let newWeather = WeatherData() //об'єкт моделі даних для Realm
    //змінна, що запускає роботу завантаження в БД. Коли в неї потрапляють дані з API, Починається додавання їх до об'єкту моделі даних, потім завантаження їх в Realm і виведення БД в консоль, після завантаження.
    private var weatherData = [WeatherModel]() {
        didSet{
            DispatchQueue.main.async { //Оо.. з діспатч моментально відпрацьовує UI
                self.createData(self.cityTextField.text!)
                print(self.weatherData)
                sleep(2) //якщо не робити сліп тут, то не встигає відпрацювати функція - і прінтує null.
                print(self.newWeather)
                self.writeToRealm(newWeather: self.newWeather)
                print("storing")
                sleep(2)
                print("retrieving")
                self.readFromRealm()
            }
        }
    }
    
    // MARK: - UI
    
    private let cityTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Type the City"
        textField.backgroundColor = .secondarySystemBackground
        textField.tintColor = .blue
        textField.textColor = .gray
        textField.font = UIFont.init(name: "Avenir-Medium", size: 22.0)
        textField.clearButtonMode = .whileEditing
        textField.layer.cornerRadius = 8
        textField.setLeftPaddingPoints(10)
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()

    private let temperatureLabel: UILabel = {
        let label = UILabel()
        label.textColor = .systemYellow
        label.font = UIFont(name: "Avenir-Medium", size: 40)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let feelsLikeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .gray
        label.font = UIFont(name: "Avenir-Light", size: 17)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let weatherDescriptionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Avenir-LightOblique", size: 30)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let pressureLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Avenir-Medium", size: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let humidityLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Avenir-Medium", size: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let windSpeedLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont(name: "Avenir-Medium", size: 20)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let buttonSearch: UIButton = {
        let button = UIButton()
        button.setTitle("GET WEATHER", for: .normal)
        button.setTitleColor(.blue, for: .normal)
        button.setTitleColor(.systemGray4, for: .highlighted)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 8
        button.layer.shadowRadius = 5
        button.layer.shadowOpacity = 0.2
        button.layer.shadowOffset = CGSize(width: 5, height: 5)
        button.layer.shadowColor = UIColor.black.cgColor
        button.addTarget(self, action: #selector(getWeather), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cityTextField.delegate = self
        view.backgroundColor = .systemBackground
        
        configureNavBar()
        addSubview()
        applyConstraints()
        //сетапимо реалм
        setupRealm()
    }
    
    private func addSubview() {
        view.addSubview(cityTextField)
        view.addSubview(buttonSearch)
        view.addSubview(temperatureLabel)
        view.addSubview(feelsLikeLabel)
        view.addSubview(weatherDescriptionLabel)
        view.addSubview(pressureLabel)
        view.addSubview(humidityLabel)
        view.addSubview(windSpeedLabel)
    }
    
    private func configureNavBar() {
        title = "Weather"
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationController?.navigationBar.tintColor = .systemYellow // Чомусь не спрацьовує колір
   }
    
    // MARK: - Actions
    
    @objc func getWeather() {
        let city = cityTextField.text
        if let city = city {
            if city.isEmpty {
                setDefaultTextValues()
            } else {
                let cityWithSpaces = allowSpaces(city)
                
                getWeatherFromNetwork(cityWithSpaces)
                //sleep(2)
                //тут помилка, на виклик функції яка зберігає дані в модель.
                //createData(cityWithSpaces)
                //якщо просто зберігати введене в текст філд - то працює.
                //newWeather.nameCity = city
            }
        }
        //sleep(2)
//        self.weathers.append(newWeather)
//        self.writeToRealm(newWeather: newWeather)
//        print("storing")
//        sleep(1)
//        print("retrieving")
//        readFromRealm()
    }
    
    // MARK: - Constraints
    
    private func applyConstraints() {
        let cityTextFieldConstraints = [
            cityTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            cityTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 250),
            cityTextField.widthAnchor.constraint(equalToConstant: 250),
            cityTextField.heightAnchor.constraint(equalToConstant: 50)
        ]
        
        let buttonSearchConstraints = [
            buttonSearch.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            buttonSearch.topAnchor.constraint(equalTo: cityTextField.bottomAnchor, constant: 20),
            buttonSearch.widthAnchor.constraint(equalToConstant: 150),
            buttonSearch.heightAnchor.constraint(equalToConstant: 50)
        ]
        
        let temperatureLabelConstraints = [
            temperatureLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            temperatureLabel.topAnchor.constraint(equalTo: buttonSearch.bottomAnchor, constant: 50)
        ]
        
        let feelsLikeLabelConstraints = [
            feelsLikeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            feelsLikeLabel.topAnchor.constraint(equalTo: temperatureLabel.bottomAnchor, constant: 10)
        ]

        let weatherDescriptionLabelConstraints = [
            weatherDescriptionLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            weatherDescriptionLabel.topAnchor.constraint(equalTo: feelsLikeLabel.bottomAnchor, constant: 50)
        ]
        
        let pressureLabelConstraints = [
            pressureLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pressureLabel.topAnchor.constraint(equalTo: weatherDescriptionLabel.bottomAnchor, constant: 50)
        ]
        
        let humidityLabelConstraints = [
            humidityLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            humidityLabel.topAnchor.constraint(equalTo: pressureLabel.bottomAnchor, constant: 10)
        ]
        
        let windSpeedLabelConstraints = [
            windSpeedLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            windSpeedLabel.topAnchor.constraint(equalTo: humidityLabel.bottomAnchor, constant: 10)
        ]
        
        NSLayoutConstraint.activate(cityTextFieldConstraints)
        NSLayoutConstraint.activate(buttonSearchConstraints)
        NSLayoutConstraint.activate(temperatureLabelConstraints)
        NSLayoutConstraint.activate(feelsLikeLabelConstraints)
        NSLayoutConstraint.activate(weatherDescriptionLabelConstraints)
        NSLayoutConstraint.activate(pressureLabelConstraints)
        NSLayoutConstraint.activate(humidityLabelConstraints)
        NSLayoutConstraint.activate(windSpeedLabelConstraints)
    }
    
    // MARK: - Private
    
    //load data from API
    private func getWeatherFromNetwork(_ city: String) {
        Network.shared.getWeather(city) { [weak self] (weather, error) in
            DispatchQueue.main.async {
                if let temperature = weather?.main?.temperature {
                    self?.temperatureLabel.text = String(format: "%.0f", round(temperature)) + Constants.temperature
                }
                if let feels = weather?.main?.feels_like {
                    self?.feelsLikeLabel.text = Constants.feels + String(format: "%.0f", round(feels)) + Constants.temperature
                }
                if let longWeather = weather?.weather?[0].description {
                    self?.weatherDescriptionLabel.text = longWeather
                }
                if let pressure = weather?.main?.pressure {
                    self?.pressureLabel.text = Constants.pressure + String(pressure) + " Pa"
                }
                if let humidity = weather?.main?.humidity {
                    self?.humidityLabel.text = Constants.humidity + String(humidity) + " %"
                }
                if let speed = weather?.wind?.speed {
                    self?.windSpeedLabel.text = Constants.windSpeed + String(speed) + " m/s"
                }
                if let weather = weather { //зберігає опціональні значення, ніяк не можу достукатися до значень(if let не допомагає)
                    self!.weatherData.append(weather)
                }
            }
        }
    }
    
    private func allowSpaces(_ city: String) -> String {
        return city.addingPercentEncoding(withAllowedCharacters:NSCharacterSet.urlQueryAllowed)!
    }
    
    private func setDefaultTextValues() {
        temperatureLabel.text = nil
        feelsLikeLabel.text = nil
        weatherDescriptionLabel.text = nil
        pressureLabel.text = nil
        humidityLabel.text = nil
        windSpeedLabel.text = nil
    }
    
    //load data for Realm model
    private func createData(_ city: String) {
        Network.shared.getWeather(city) { [weak self]  (weather, error)  in
            DispatchQueue.global(qos: .background).async {
                if let city = weather?.name {
                    self?.newWeather.nameCity = city
                }
                if let temperature = weather?.main?.temperature {
                    self?.newWeather.temperatures = temperature
                }
                if let feels = weather?.main?.feels_like {
                    self?.newWeather.feelsLike = feels
                }
                if let longWeather = weather?.weather?[0].description {
                    self?.newWeather.descriptions = longWeather
                }
                if let pressure = weather?.main?.pressure {
                    self?.newWeather.pressures = pressure
                }
                if let humidity = weather?.main?.humidity {
                    self?.newWeather.humidities = humidity
                }
                if let speed = weather?.wind?.speed {
                    self?.newWeather.windSpeed = speed
                }
            }
        }
    }
    
    // MARK: - Realm setting

    func setupRealm() {
        //створюємо нашу кастомну конфігурацію
        let config = Realm.Configuration(
            schemaVersion: 1,//версія конфігурації
            //створюємо блок для міграції, який описує, що ми будемо робити при міграції БД
            migrationBlock: { migration, oldSchema in
                if oldSchema > 1 { print("Do nothing!") } //типу коли версія БД міняється, то треба змінити schemaVersion: 2 і тут oldSchema > 2.. і так кожного разу додавати, коли мігрує БД. Якщо не змінити, то БД працювати не буде і напише, що відбулася зміна  і опише, що саме змінилося. Воно розуміє, якщо зроблена зміна в БД, в її структурі.
            })
        //тепер треба засетити нашу конфігурацію замість дефолтної
        Realm.Configuration.defaultConfiguration = config
        do {
            realm = try Realm()//ініціалізуємо наш Realm об'єкт
        } catch let error as NSError {//для чого робимо цей каст до NSError, щоб можна било роздрукувати у випадку помилки error.localizedDescription - щоб побачити опис помилки
            print(error.localizedDescription)
        }
    }

    //запис з моделі в Realm
    private func writeToRealm(newWeather: WeatherData) {
        do {
            try realm?.write({
                realm?.add(newWeather)
            })
        } catch let error as NSError {
            print(error.localizedDescription)
        }
    }

    //зчитування
    private func readFromRealm() {
        let result = realm?.objects(WeatherData.self).sorted(byKeyPath: "nameCity", ascending: true)//примінила сортування даних
        if let result = result {
            for weather in result {
                //weathers.append(weather)
                print(weather)
            }
        }
    }
}



// MARK: - Extensions

extension ViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        cityTextField.resignFirstResponder()
        return true
    }
}

//для відступу зліва для тексту в TextField
extension UITextField {

    func setLeftPaddingPoints(_ amount:CGFloat){
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
            self.leftView = paddingView
            self.leftViewMode = .always
        }
}

