//
//  TaskListViewModel.swift
//  VeroDigitalProject
//
//  Created by Ivo Vasilski on 4.12.24.
//
import Foundation
import Combine

class TaskListViewModel: ObservableObject {
    @Published private(set) var state: ViewState = .loading
    private var tasks: [Task] = []
    private var filteredTasks: [Task] = []
    private var accessToken: String?
    private let baseURL = "https://api.baubuddy.de"
    private var cancellables = Set<AnyCancellable>()
    private let userDefaultsKey = "SavedTasks"

    // MARK: - Initialization

    init() {
        loadTasksFromStorage()
    }

    // MARK: - Intent Handling

    func handle(intent: TaskListIntent) {
        switch intent {
        case .loadTasks:
            loadTasks()
        case .refresh:
            refreshTasks()
        case .search(let query):
            searchTasks(query: query)
        case .scanQRCode(let code):
            searchTasks(query: code)
        }
    }

    // MARK: - Search

    private func searchTasks(query: String) {
        let query = query.lowercased()
        filteredTasks = tasks.filter { task in
            let taskText = task.task.lowercased()
            let titleText = task.title.lowercased()
            let descriptionText = task.description.lowercased()
            let colorCodeText = (task.colorCode ?? "").lowercased()

            return taskText.contains(query) ||
                titleText.contains(query) ||
                descriptionText.contains(query) ||
                colorCodeText.contains(query)
        }
        state = filteredTasks.isEmpty ? .empty : .success(filteredTasks)
    }

    // MARK: - Authentication

    private func authenticate(completion: @escaping (Result<Void, Error>) -> Void) {
        let url = URL(string: baseURL + "/index.php/login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Basic QVBJX0V4cGxvcmVyOjEyMzQ1NmlzQUxhbWVQYXNz", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["username": "365", "password": "1"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])

        URLSession.shared.dataTaskPublisher(for: request)
            .tryMap { output -> String in
                guard let json = try? JSONSerialization.jsonObject(with: output.data, options: []) as? [String: Any],
                      let oauth = json["oauth"] as? [String: Any],
                      let token = oauth["access_token"] as? String else {
                    throw URLError(.badServerResponse)
                }
                return token
            }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { result in
                switch result {
                case .finished: break
                case .failure(let error): completion(.failure(error))
                }
            }, receiveValue: { [weak self] token in
                self?.accessToken = token
                completion(.success(()))
            })
            .store(in: &cancellables)
    }

    // MARK: - Storage

    private func loadTasksFromStorage() {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsKey),
           let savedTasks = try? JSONDecoder().decode([Task].self, from: savedData) {
            self.tasks = savedTasks
            self.filteredTasks = savedTasks
            self.state = savedTasks.isEmpty ? .empty : .success(savedTasks)
        } else {
            self.state = .loading
        }
    }

    private func saveTasksToStorage() {
        if let data = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
    }

    // MARK: - API Integration

    private func loadTasks() {
        guard let token = accessToken else {
            authenticate { [weak self] result in
                switch result {
                case .success:
                    self?.loadTasks()
                case .failure(let error):
                    DispatchQueue.main.async {
                        self?.state = .error(error.localizedDescription)
                    }
                }
            }
            return
        }

        let url = URL(string: baseURL + "/dev/index.php/v1/tasks/select")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .decode(type: [Task].self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    DispatchQueue.main.async {
                        self?.state = .error(error.localizedDescription)
                    }
                }
            }, receiveValue: { [weak self] tasks in
                self?.tasks = tasks
                self?.filteredTasks = tasks
                self?.saveTasksToStorage()
                self?.state = tasks.isEmpty ? .empty : .success(tasks)
            })
            .store(in: &cancellables)
    }

    private func refreshTasks() {
        tasks.removeAll()
        filteredTasks.removeAll()
        state = .loading
        loadTasks()
    }
}





