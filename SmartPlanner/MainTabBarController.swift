//
//  MainTabBarController.swift
//  SmartPlanner
//
//  Created by valentina balde on 11/30/25.
//

import UIKit

final class MainTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
    }

    private func setupTabs() {
        let homeVC = HomeViewController()
        homeVC.title = "Главная"

        let tasksVC = TasksViewController()
        tasksVC.title = "Задачи"

        let notesVC = NotesViewController()
        notesVC.title = "Записи"

        let homeNav = UINavigationController(rootViewController: homeVC)
        let tasksNav = UINavigationController(rootViewController: tasksVC)
        let notesNav = UINavigationController(rootViewController: notesVC)

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

        notesNav.tabBarItem = UITabBarItem(
            title: "Записи",
            image: UIImage(systemName: "square.and.pencil"),
            selectedImage: UIImage(systemName: "square.and.pencil")
        )

        viewControllers = [homeNav, tasksNav, notesNav]
    }
}

