//
//  AppDelegate.swift
//  Franziskaneum
//
//  Created by Niko Kirste on 03.01.16.
//  Copyright © 2016 Franziskaneum. All rights reserved.
//

import UIKit
import UserNotifications

import Firebase
import FirebaseMessaging
import FirebaseInstanceID

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var reachability: Reachability!
	var window: UIWindow?
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
		FIRApp.configure()
		registerForRemoteNotifications(application)
		
		// Add observer for InstanceID token refresh callback.
		NotificationCenter.default.addObserver(self, selector: #selector(self.tokenRefreshNotification), name: .firInstanceIDTokenRefresh, object: nil)
		
		// Reconnect to fcm if we lost the connection
		/**
		reachability = Reachability()!
		NotificationCenter.default.addObserver(self, selector: #selector(self.reachabilityChanged), name: ReachabilityChangedNotification, object: reachability)
		do {
		try reachability.startNotifier()
		} catch {
		print("could not start reachability notifier")
		}
		**/
		
		self.window?.tintColor = UIColor.franziskaneum
		
		return true
	}
	
	func registerForRemoteNotifications(_ application: UIApplication) {
		if #available(iOS 10.0, *) {
			let authOptions : UNAuthorizationOptions = [.alert, .badge, .sound]
			UNUserNotificationCenter.current().requestAuthorization(options: authOptions, completionHandler: { (granted, error) in
				print("\(granted), \(error)")
			})
			
			// For iOS 10 display notification (sent via APNS)
			UNUserNotificationCenter.current().delegate = self
			// For iOS 10 data message (sent via FCM)
			FIRMessaging.messaging().remoteMessageDelegate = self
			
		} else {
			let settings: UIUserNotificationSettings =
				UIUserNotificationSettings(types: [UIUserNotificationType.alert, UIUserNotificationType.badge, UIUserNotificationType.sound], categories: nil)
			application.registerUserNotificationSettings(settings)
		}
		
		application.registerForRemoteNotifications()
	}
	
	func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		FIRInstanceID.instanceID().setAPNSToken(deviceToken, type: FIRInstanceIDAPNSTokenType.unknown)
	}
	
	func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		print("Failed to register for remote notifications: \(error.localizedDescription)")
	}
	
	func tokenRefreshNotification(_ notification: Notification) {
		if let refreshedToken = FIRInstanceID.instanceID().token() {
			print("InstanceID token: \(refreshedToken)")
		}
		
		// Connect to FCM since connection may have failed when attempted before having a token.
		connectToFcm()
	}
	
	func connectToFcm() {
		/**
		FIRMessaging.messaging().connect { (error) in
		if let error = error {
		print("Unable to connect to FCM. \(error)")
		
		FIRMessaging.messaging().disconnect()
		DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5.0) {
		self.connectToFcm()
		}
		} else {
		print("Connected to FCM.")
		
		FIRMessaging.messaging().subscribe(toTopic: "/topics/vplan")
		print("subscribed to \"/topics/vplan\"")
		}
		}
		**/
		
		FIRMessaging.messaging().connect() { (error) in
			if let error = error {
				print("Unable to connect to FCM. \(error)")
			} else {
				print("Connected to FCM.")
				
				FIRMessaging.messaging().subscribe(toTopic: "/topics/vplan")
				print("subscribed to \"/topics/vplan\"")
			}
		}
	}
	
	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		print("Remote Notification with CompletionHandler")
		
		if let value = userInfo["new_vplan_available"] as? String, value.boolValue {
			VPlanNotificationTask().performTask() { (error: FranziskaneumError?) in
				if error != nil {
					completionHandler(.failed)
				} else {
					completionHandler(.newData)
				}
			}
		} else {
			completionHandler(.noData)
		}
	}
	
	var isReachable = false
	
	func reachabilityChanged(_ notification: Notification) {
		print("reachability changed \(reachability.currentReachabilityString)")
		
		if reachability.isReachable && !isReachable {
			connectToFcm()
		}
		
		isReachable = reachability.isReachable
	}
	
	func applicationDidBecomeActive(_ application: UIApplication) {
		connectToFcm()
		
		application.applicationIconBadgeNumber = 0
	}
	
	func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
		if let userInfo = notification.userInfo {
			if let vplanDayTitle = userInfo["vplan_day_title"] as? String {
				openVPlanDay(vplanDayTitle: vplanDayTitle)
			}
		}
	}
	
	func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
		print("\(url.absoluteString)")
		
		switch(url.host!) {
		case "vplan":
			let pathParts = url.path.components(separatedBy: "/")
			print("\(pathParts[1])")
			
			openVPlanDay(vplanDayTitle: pathParts[1])
			
			break
		default:
			break
		}
		
		return true
	}
	
	func openVPlanDay(vplanDayTitle: String) {
		let viewController = self.window?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: "VPlanDayControlViewController") as! VPlanDayControlViewController
		viewController.vplanTitle = vplanDayTitle
		viewController.showMyChangesSegment = true
		
		if let baseViewController = self.window?.rootViewController as? BaseViewController {
			baseViewController.selectedIndex = 1
			(baseViewController.selectedViewController as! UINavigationController).popToRootViewController(animated: false)
			(baseViewController.selectedViewController as! UINavigationController).pushViewController(viewController, animated: true)
		}
		
	}
}

@available(iOS 10, *)
extension AppDelegate : UNUserNotificationCenterDelegate {
	// Receive displayed notifications for iOS 10 devices.
	func userNotificationCenter(_ center: UNUserNotificationCenter,
	                            willPresent notification: UNNotification,
	                            withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		let userInfo = notification.request.content.userInfo
		
		if let vplanDayTitle = userInfo["vplan_day_title"] as? String {
			let viewController = self.window?.rootViewController?.storyboard?.instantiateViewController(withIdentifier: "VPlanDayControlViewController") as! VPlanDayControlViewController
			viewController.vplanTitle = vplanDayTitle
			viewController.showMyChangesSegment = true
			
			if let baseViewController = self.window?.rootViewController as? BaseViewController {
				baseViewController.selectedIndex = 1
				(baseViewController.selectedViewController as! UINavigationController).pushViewController(viewController, animated: true)
			}
		}
	}
}

extension AppDelegate : FIRMessagingDelegate {
	// Receive data message on iOS 10 devices while app is in the foreground.
	func applicationReceivedRemoteMessage(_ remoteMessage: FIRMessagingRemoteMessage) {
		print("Remote Message")
		
		if let value = remoteMessage.appData["new_vplan_available"] as? String, value.boolValue {
			VPlanNotificationTask().performTask() { (error: FranziskaneumError?) in
			}
		}
	}
}
