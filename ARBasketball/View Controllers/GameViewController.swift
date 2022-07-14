//
//  ViewController.swift
//  Basketball
//
//  Created by Андрей on 13.07.2022.
//

import ARKit

class GameViewController: UIViewController, ARSCNViewDelegate, SCNPhysicsContactDelegate {
    
    // MARK: - Outlets
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet var scoreLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    
    // MARK: - Properties
    var segue: UIStoryboardSegue!
    
    
    let configuration = ARWorldTrackingConfiguration()
    var count = 0 {
        didSet {
            DispatchQueue.main.async {
                self.scoreLabel.text = "Score: \(self.count)"
                UIView.animate(withDuration: 0.3) {
                    self.scoreLabel.transform = CGAffineTransform(scaleX: 3, y: 3)
                    self.scoreLabel.transform = CGAffineTransform.identity
                }
            }
        }
    }
    var isFirstTouchTopPlane = true
    var isFirstTouchBottomPlane = true
    var isGoal = false
    
    var isHoopAdded = false {
        didSet {
            configuration.planeDetection = []
            sceneView.session.run(configuration, options: .removeExistingAnchors)
        }
    }
    
    // MARK: - UIViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        // Set the view's delegate
        sceneView.delegate = self
        sceneView.scene.physicsWorld.contactDelegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Detect vertical planes
        configuration.planeDetection = .vertical
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // Check contacts
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        
        // Check contact with top plane
        if contact.nodeA.physicsBody!.categoryBitMask | 2 != 0 && contact.nodeA.name == "topPlane" {
            guard isFirstTouchTopPlane else { return }
            isFirstTouchTopPlane = false
            isGoal = true
        }
        
        // Check contact with bottom plane
        if contact.nodeA.physicsBody!.categoryBitMask | 4 != 0 && isFirstTouchTopPlane == false && isGoal == true && contact.nodeA.name == "bottomPlane" {
            guard isFirstTouchBottomPlane else { return }
            isFirstTouchBottomPlane = false
            count += 1
        }
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ResultViewController" else { return }
        let destination = segue.destination as! ResultViewController
        destination.textLabel = scoreLabel.text
        sceneView.scene = SCNScene()
    }
    
    // MARK: - Methods
    func getBall() -> SCNNode? {
        // Get current frame
        guard let frame = sceneView.session.currentFrame else { return nil }
        
        // Get camera transform
        let cameraTransform = frame.camera.transform
        let matrixCameraTransform = SCNMatrix4(cameraTransform)
        
        // Ball geometry
        let ball = SCNSphere(radius: 0.15)
        ball.firstMaterial?.diffuse.contents = UIImage(named: "basketball.png")
        
        // Ball node
        let ballNode = SCNNode(geometry: ball)
        
        // Add physics body
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ballNode))
        
        // Calculate force for pushing the ball
        let power = Float(7)
        let x = -matrixCameraTransform.m31 * power
        let y = -matrixCameraTransform.m32 * power
        let z = -matrixCameraTransform.m33 * power
        let forceDirection = SCNVector3(x, y, z)
        
        // Apply force
        ballNode.physicsBody?.applyForce(forceDirection, asImpulse: true)
        
        // Assign camera position to ball
        ballNode.simdTransform = cameraTransform
        
        // Add name and masks
        ballNode.name = "ball"
        ballNode.physicsBody?.categoryBitMask = 8
        ballNode.physicsBody?.contactTestBitMask = 6

        
        return ballNode
    }
    
    func getHoopNode() -> SCNNode {
        let scene = SCNScene(named: "Hoop.scn", inDirectory: "art.scnassets")!
        
        let hoopNode = scene.rootNode.clone()

        for (index, childrenNode) in hoopNode.childNodes.enumerated() {
            if let _ = childrenNode.geometry as? SCNPlane {
                // Add physics body
                childrenNode.physicsBody = SCNPhysicsBody(
                    type: .static,
                    shape: SCNPhysicsShape()
                )
                
                // Add masks
                childrenNode.physicsBody?.categoryBitMask = index == hoopNode.childNodes.count - 1 ? 4 : 2
                childrenNode.physicsBody?.collisionBitMask = 0
                
                childrenNode.opacity = 0
            } else {
                // Add physics body
                childrenNode.physicsBody = SCNPhysicsBody(
                    type: .static,
                    shape: SCNPhysicsShape(
                        node: childrenNode,
                        options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]
                    )
                )
                childrenNode.physicsBody?.categoryBitMask = 8
            }
        }
        
        return hoopNode
    }
    
    func getPlaneNode(for anchor: ARPlaneAnchor) -> SCNNode {
        let extent = anchor.extent
        let plane = SCNPlane(width: CGFloat(extent.x), height: CGFloat(extent.z))
        plane.firstMaterial?.diffuse.contents = UIColor.green
        
        // Create 25% transparent plane node
        let planeNode = SCNNode(geometry: plane)
        planeNode.opacity = 0.25
        
        // Rotate plane node
        planeNode.eulerAngles.x -= .pi / 2
        return planeNode
    }
    
    func updatePlaneNode(_ node: SCNNode, for anchor: ARPlaneAnchor) {
        guard let planeNode = node.childNodes.first, let plane = planeNode.geometry as? SCNPlane else {
            return
        }
        
        // Change plane node center
        planeNode.simdPosition = anchor.center
        
        // Change plane size
        let extent = anchor.extent
        plane.width = CGFloat(extent.x)
        plane.height = CGFloat(extent.z)
    }
    
    // MARK: - ARSCNViewDelegate
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else {
            return
        }
        
        // Add the hoop to the center of detected vertical plane
        node.addChildNode(getPlaneNode(for: planeAnchor))
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor, planeAnchor.alignment == .vertical else {
            return
        }
        
        // Update plane node
        updatePlaneNode(node, for: planeAnchor)
    }
    
    // MARK: - Actions
    @IBAction func userTapped(_ sender: UITapGestureRecognizer) {
        if isHoopAdded {
            // Get basketball node
            guard let ballNode = getBall() else { return }
            
            ballNode.runAction(
                .sequence([
                    .wait(duration: 1.5),
                    .fadeOut(duration: 1.5),
                    .removeFromParentNode(),
                ])
            )
            
            // Add basketball to the camera position
            sceneView.scene.rootNode.addChildNode(ballNode)
            
            if isFirstTouchTopPlane == false {
                isFirstTouchTopPlane = true
            }
            
            if isFirstTouchBottomPlane == false {
                isFirstTouchBottomPlane = true
            }
        } else {
            let location = sender.location(in: sceneView)
            
            guard let result = sceneView.hitTest(location, types: .existingPlaneUsingExtent).first else {
                return
            }
            
            guard let anchor = result.anchor as? ARPlaneAnchor, anchor.alignment == .vertical else {
                return
            }
            
            // Get hoop node and set its coordinates to the point of user touch
            let hoopNode = getHoopNode()
            hoopNode.simdTransform = result.worldTransform
            
            // Rotate hoop by 90 degrees
            hoopNode.eulerAngles.x -= .pi / 2
            
            isHoopAdded = true
            sceneView.scene.rootNode.addChildNode(hoopNode)
            scoreLabel.isHidden = false
            messageLabel.isHidden = true
        }
    }
}
