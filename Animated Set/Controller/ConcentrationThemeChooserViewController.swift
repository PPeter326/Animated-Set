//
//  ConcentrationThemeChooserViewController.swift
//  Concentration
//
//  Created by Peter Wu on 5/29/18.
//  Copyright © 2018 Zero. All rights reserved.
//

import UIKit

class ConcentrationThemeChooserViewController: UIViewController, UISplitViewControllerDelegate {

    let emojiThemes = [
        "Gestures": "🤲👍👏👊✍️👈💪👌✊🤝👇🙏🖕🖐🤞🤜🤘",
        "Fruits": "🍏🍌🍇🥥🥦🍍🍋🍅🍊🍎🍉🍓🥝🍐🍒🥔🥑",
        "Sports": "⚽️🏀🏈⚾️🎾🏐🏉🎱🏓🏸🥅🏒🏑🏏⛳️🏹⛷",
    ]

    @IBAction func changeTheme(_ sender: Any) {
        // Only perform segue (and instantiate a new game) if it's not in a split view controller
        if let cvc = splitViewDetailConcentrationViewController {
            if let themeName = (sender as? UIButton)?.currentTitle,
                let theme = emojiThemes[themeName] {
                cvc.theme = theme
            }
            
        } else if let cvc = concentrationViewController { // if we can get a hold of the strong reference to the concentration view controller
            if let themeName = (sender as? UIButton)?.currentTitle,
                let theme = emojiThemes[themeName] {
                cvc.theme = theme
            }
            // push concentation view controller onto the navigation stack
            navigationController?.pushViewController(cvc, animated: true)
        } else { // Only perform segue (and instantiage new instance of game) if not in split view or no strong reference to an existing instance of concentration viewcontroller
            performSegue(withIdentifier: "Choose Theme", sender: sender)
        }
    }
    
    override func awakeFromNib() {
        splitViewController?.delegate = self
    }
    
    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        // return true to prevent secondary view controller collpasing onto primary view controller
        // If no theme has been chosen, return true so the game starts at choosing theme
        // if a theme has already been chosen, do collapse
        if let cvc = secondaryViewController as? ConcentrationViewController {
            if cvc.theme != nil {
                return false
            }
        }
        return true
    }
    private var splitViewDetailConcentrationViewController: ConcentrationViewController? {
        return splitViewController?.viewControllers.last as? ConcentrationViewController
    }
    private var concentrationViewController: ConcentrationViewController?
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Choose Theme" {
            if let themeName = (sender as? UIButton)?.currentTitle,
                let theme = emojiThemes[themeName] {
                if let cvc = segue.destination as? ConcentrationViewController {
                    cvc.theme = theme
                    // hold on to the concentration view controller in memory
                    concentrationViewController = cvc
                }
            }
        }
    }
    

}
