//
//  HealthManager.swift
//  HKTutorial
//
//  Created by ernesto on 18/10/14.
//  Copyright (c) 2014 raywenderlich. All rights reserved.
//

import HealthKit
import Foundation

class HealthManager {
  
  let healthKitStore:HKHealthStore = HKHealthStore()
  
  
  func authorizeHealthKit(completion: ((success:Bool, error:NSError!) -> Void)!)
  {
    // 1. Set the types you want to read from HK Store
    let healthKitTypesToRead:Set = [
      HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierDateOfBirth),
      HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBloodType),
      HKObjectType.characteristicTypeForIdentifier(HKCharacteristicTypeIdentifierBiologicalSex),
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMass),
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierHeight),
      HKObjectType.workoutType()
    ]
    // 2. Set the types you want to write to HK Store
    let healthKitTypesToWrite:Set = [
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierBodyMassIndex),
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierActiveEnergyBurned),
      HKObjectType.quantityTypeForIdentifier(HKQuantityTypeIdentifierDistanceWalkingRunning),
      HKQuantityType.workoutType()
    ]
    
    // 3. If the store is not available (for instance, iPad) return an error and don't go on.
    if !HKHealthStore.isHealthDataAvailable()
    {
      let error = NSError(domain: "com.raywenderlich.tutorials.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey:"HealthKit is not available in this Device"])
      if( completion != nil )
      {
        completion(success:false, error:error)
      }
      return;
    }
    
    // 4.  Request HealthKit authorization
    healthKitStore.requestAuthorizationToShareTypes(healthKitTypesToWrite, readTypes: healthKitTypesToRead) { (success, error) -> Void in
      
      if( completion != nil )
      {
        completion(success:success,error:error)
      }
    }
  }
  
  
  func readProfile() -> (age:Int?, biologicalSex:HKBiologicalSexObject?, bloodType:HKBloodTypeObject?)
  {
    var error:NSError?
    var age:Int?
    
    
    //1 request birthday and calculate age
    if let birthDay = healthKitStore.dateOfBirthWithError(&error)
    {
      let today = NSDate()
      let calendar = NSCalendar.currentCalendar()
      let differenceComponents = NSCalendar.currentCalendar().components(.CalendarUnitYear, fromDate: birthDay, toDate: today, options: NSCalendarOptions(0) )
      age = differenceComponents.year
    }
    if error != nil {
      println("Error reading Birthday: \(error)")
    }
    
    //2. Read biological sex
    var biologicalSex:HKBiologicalSexObject? = healthKitStore.biologicalSexWithError(&error)
    if error != nil {
      println("Error reading biological sex: \(error)")
      
    }
    
    
    //3. read blood type
    var bloodType:HKBloodTypeObject? = healthKitStore.bloodTypeWithError(&error)
    if error != nil{
      println("Error readling blood type")
    }
    
    
    //4. return the information read in a tuple
    return (age, biologicalSex, bloodType)
  }
  
  func readMostRecentSample(sampleType:HKSampleType, completion: ((HKSample!, NSError!) -> Void)!)
  {
      //1. build the predicate
    let past = NSDate.distantPast() as! NSDate
    let now = NSDate()
    let mostRecentPredicate = HKQuery.predicateForSamplesWithStartDate(past, endDate:now, options: .None)
    
    
    //2. build the sort descriptor to return the samples in decending order
    let sortDescriptor = NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending: false)
    //3. we want to limit the number of samples returned by the query to just 1 (the most recent)
    let limit = 1
    
    //4 build the samples query
    let sampleQuery = HKSampleQuery(sampleType: sampleType, predicate: mostRecentPredicate, limit: limit, sortDescriptors: [sortDescriptor])
      {
        (sampleQuery, results, error) -> Void in
        
        if let queryError = error {
          completion(nil,error)
          return;
        }
        
        // get the first sample
        let mostRecentSample = results.first as? HKQuantitySample
        
        // execute the completion closure
        if completion != nil {
          completion(mostRecentSample,nil)
          
        }
    }
    
    //5. execute the query
    self.healthKitStore.executeQuery(sampleQuery)
    
    
    
    
    
  }
  
  
// end of class
}