//
//  ViewController.swift
//  HisogramSpecificationBlendDemo
//
//  Created by Simon Gladman on 09/05/2016.
//  Copyright © 2016 Simon Gladman. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let imageView = UIImageView()
    let context = CIContext()
    
    let gradientImage = CIFilter(
        name: "CIRadialGradient",
        withInputParameters: [
            kCIInputCenterKey:
                CIVector(x: 340, y: 300),
            "inputRadius0": 100,
            "inputRadius1": 150,
            "inputColor0":
                CIColor(red: 0, green: 0, blue: 0),
            "inputColor1":
                CIColor(red: 1, green: 1, blue: 1)
        ])?
        .outputImage
    
    let mona = CIImage(image: UIImage(named: "centerMona.jpg")!)!
    
    let segmentedControl = UISegmentedControl(items: ["blueberry", "lemon", "lime", "strawberry"])
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
    
        imageView.contentMode = .Center
        view.addSubview(imageView)
        view.addSubview(segmentedControl)
        
        segmentedControl.addTarget(
            self,
            action: #selector(ViewController.segmentedControlValueChanged),
            forControlEvents: .ValueChanged)
        
        segmentedControl.selectedSegmentIndex = 0
        segmentedControlValueChanged()
    }
    
    func segmentedControlValueChanged()
    {
        if let fruitImage = UIImage(named: segmentedControl.titleForSegmentAtIndex(segmentedControl.selectedSegmentIndex) ?? "" + ".png")
        {
            displayComposite(fruitImage)
        }
    }
    
    func displayComposite(image: UIImage)
    {
        guard let image = CIImage(image: image) else
        {
            return
        }
        
        let specification = HistogramSpecification()
        specification.inputImage = mona
        specification.inputHistogramSource = image

        let composite = CIFilter(
            name: "CIBlendWithMask",
            withInputParameters: [
                kCIInputImageKey: image,
                kCIInputBackgroundImageKey: specification.outputImage!,
                "inputMaskImage": gradientImage!])!
        
        
        let final = context.createCGImage(
            composite.outputImage!,
            fromRect: composite.outputImage!.extent)

        imageView.image = UIImage(CGImage: final)
    }

    override func viewDidLayoutSubviews()
    {
        imageView.frame = view.bounds
        
        segmentedControl.frame = CGRect(
            x: 0,
            y: topLayoutGuide.length,
            width: view.frame.width,
            height: segmentedControl.intrinsicContentSize().height).insetBy(dx: 5, dy: 0)
    }


}

