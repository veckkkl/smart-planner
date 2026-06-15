//
//  MainTabBarController.swift
//  SmartPlanner
//

import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }

    private func setupTabs() {
        let newsVC = NewsViewController()
        newsVC.title = "Новости"

        let homeVC = HomeViewController()
        homeVC.title = "Главная"

        let tasksVC = TasksViewController()
        tasksVC.title = "Задачи"

        let newsNav = UINavigationController(rootViewController: newsVC)
        let homeNav = UINavigationController(rootViewController: homeVC)
        let tasksNav = UINavigationController(rootViewController: tasksVC)

        newsNav.tabBarItem = UITabBarItem(
            title: "Новости",
            image: UIImage(systemName: "newspaper"),
            selectedImage: UIImage(systemName: "newspaper.fill")
        )

        homeNav.tabBarItem = UITabBarItem(
            title: "Главная",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )

        tasksNav.tabBarItem = UITabBarItem(
            title: "Задачи",
            image: UIImage(systemName: "checklist"),
            selectedImage: UIImage(systemName: "checklist")
        )

        viewControllers = [newsNav, homeNav, tasksNav]
        selectedIndex = 1
    }
}
