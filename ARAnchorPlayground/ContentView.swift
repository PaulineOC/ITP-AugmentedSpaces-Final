//  Created by Nien Lam on 10/13/21.
// Altered by Pauline & Rajshree

import SwiftUI
import ARKit
import RealityKit
import Combine


// MARK: - Game Constants
//Coral Formation:
let currentTimerLength = 15
let startingLava = 2
let larvaRequired = 3

//MARK: Interactive States
enum AppMode {
    case START
    case INTRO
    case CORAL_FORMATION
    case CORAL_COMMUNITY
    case CORAL_BLEACHING
}
enum IntroState{
    case INSTRUCTIONS
    case CORAL_FACTS
}

enum CoralFormationState{
    case INTRO
    case INTSTRUCTIONS
    case CREATION
    case SUCCESS
}

enum CoralCommunityState{
    case INSTRUCTIONS
    case FOUND_COMMUNITY
    case JOINED_COMMUNITY
}

enum CoralBleachingState{
    case INTRO
    case INSTRUCTIONS
    case SUCCESS
    case FAILURE
}


// MARK: - View model for handling communication between the UI and ARView.
class ViewModel: ObservableObject {
    
    // App / Game States
    @Published var appMode: AppMode = AppMode.INTRO
    @Published var currentIntroState: IntroState =  IntroState.INSTRUCTIONS
    @Published var currentCoralFormationState: CoralFormationState =  CoralFormationState.INTRO
    @Published var currentCoralCommunityState: CoralCommunityState =  CoralCommunityState.INSTRUCTIONS
    @Published var currentCoralBleachingState: CoralBleachingState =  CoralBleachingState.INTRO

    let uiSignal = PassthroughSubject<UISignal, Never>()

    enum UISignal {
        case reset
    }
}


// MARK: - UI Layer.
struct ContentView : View {
    @StateObject var viewModel: ViewModel
    
    var body: some View {
        ZStack {
            
            //AppMode.START
            if(viewModel.appMode == AppMode.START){
                
            }//end of AppMode.START
            
            else {
                
                //AppMode.Intro
                if(viewModel.appMode == AppMode.INTRO){
                    if(viewModel.currentIntroState == IntroState.INSTRUCTIONS){
                          d
                    }
                    else if(viewModel.currentIntroState == IntroState.CORAL_FACTS){}
                }//end of AppMode.Intro
                
                //AppMode.CoralFormation
                else if(viewModel.appMode == AppMode.CORAL_FORMATION){
                    if(viewModel.currentCoralFormationState == CoralFormationState.INTRO){}
                    else if(viewModel.currentCoralFormationState == CoralFormationState.INTSTRUCTIONS){}
                    else if(viewModel.currentCoralFormationState == CoralFormationState.CREATION){}
                    else if(viewModel.currentCoralFormationState == CoralFormationState.SUCCESS){}
                }//End of AppMode.CoralFormation
                
                //AppMode.CORAL_COMMUNITY
                else if(viewModel.appMode == AppMode.CORAL_COMMUNITY){
                    if(viewModel.currentCoralCommunityState == CoralCommunityState.INSTRUCTIONS){}
                    else if(viewModel.currentCoralCommunityState == CoralCommunityState.FOUND_COMMUNITY){}
                    else if(viewModel.currentCoralCommunityState == CoralCommunityState.JOINED_COMMUNITY){}
                }//End of AppMode.CORAL_COMMUNITY
                
                //AppMode.CORAL_BLEACHING
                else if(viewModel.appMode == AppMode.CORAL_BLEACHING){
                    if(viewModel.currentCoralBleachingState == CoralBleachingState.INSTRUCTIONS){}
                    else if(viewModel.currentCoralBleachingState == CoralBleachingState.INTRO){}
                    else if(viewModel.currentCoralBleachingState == CoralBleachingState.INSTRUCTIONS){}
                    else if(viewModel.currentCoralBleachingState == CoralBleachingState.FAILURE){}
                    else if(viewModel.currentCoralBleachingState == CoralBleachingState.SUCCESS){}
                }//End of AppMode.CORAL_BLEACHING
                
                
                ARViewContainer(viewModel: viewModel)

                
            }// end of main else
            
            //MARK: Testing Space (add UI that doesn't need state)
            
            // Reset button.
            Button {
                viewModel.uiSignal.send(.reset)
            } label: {
                Label("Reset", systemImage: "gobackward")
                    .font(.system(.title2).weight(.medium))
                    .foregroundColor(.white)
                    .labelStyle(IconOnlyLabelStyle())
                    .frame(width: 30, height: 30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding()
            
            
            
        }
        .edgesIgnoringSafeArea(.all)
        .statusBar(hidden: true)
    }
}


// MARK: - AR View.
struct ARViewContainer: UIViewRepresentable {
    let viewModel: ViewModel
    
    func makeUIView(context: Context) -> ARView {
        SimpleARView(frame: .zero, viewModel: viewModel)
    }
    
    func updateUIView(_ uiView: ARView, context: Context) {}
}

class SimpleARView: ARView, ARSessionDelegate {
    var viewModel: ViewModel
    var arView: ARView { return self }
    var originAnchor: AnchorEntity!
    var pov: AnchorEntity!
    var subscriptions = Set<AnyCancellable>()

    // Dictionary for tracking image anchors.
    var imageAnchorToEntity: [ARImageAnchor: AnchorEntity] = [:]
    
    var allLarva:[LarvaEntity] = []



    init(frame: CGRect, viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(frame: frame)
    }
    
    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    required init(frame frameRect: CGRect) {
        fatalError("init(frame:) has not been implemented")
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        setupScene()
        
        setupEntities()
    }
    

    func setupScene() {
        // Setup world tracking and image detection.
        let configuration = ARWorldTrackingConfiguration()
        arView.renderOptions = [.disableDepthOfField, .disableMotionBlur]

        // Create set hold target image references.
        var set = Set<ARReferenceImage>()

        // Setup target image A.
        if let detectionImage = makeDetectionImage(named: "itp-logo.jpg",
                                                   referenceName: "IMAGE_ALPHA",
                                                   physicalWidth: 0.18415) {
            set.insert(detectionImage)
        }

        // Setup target image B.
        if let detectionImage = makeDetectionImage(named: "dino.jpg",
                                                   referenceName: "IMAGE_BETA",
                                                   physicalWidth: 0.19) {
            set.insert(detectionImage)
        }


        // Add target images to configuration.
        configuration.detectionImages = set
        configuration.maximumNumberOfTrackedImages = 2

        // Run configuration.
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        
        // Called every frame.
        scene.subscribe(to: SceneEvents.Update.self) { event in
            self.renderLoop()
        }.store(in: &subscriptions)
        
        // Process UI signals.
        viewModel.uiSignal.sink { [weak self] in
            self?.processUISignal($0)
        }.store(in: &subscriptions)
        
        
        // Respond to collision events.
        arView.scene.subscribe(to: CollisionEvents.Began.self) { event in
            print("💥 Collision with \(event.entityA.name) & \(event.entityB.name)")
            
            //TODO: include state check
            
            for i in 0..<self.allLarva.count{
                            if (event.entityA.name == "larva-\(i)" && event.entityB.name == "landingStone"){
                                self.allLarva[i].handleAttachingToStone()
                                
                                //TODO: immediately stop moving the item ?
                                // Remove gesture for particular item?
                                //print(self.arView.gestureRecognizers)
                                
//                                let test = self.arView.gestureRecognizers[0]
//                                print(self.pov.orientation.angle)
//                                print(self.pov.transform.rotation)
//                                ARView.EntityGestures.translation.remove(self.allLarva[i]);
 
                                //self.arView.removeGestureRecognizer([.translation])
//                                arView.installGestures([.translation,], for: larva)

                                
                            }
                            
                        }
            
                    
            
            
            
           }.store(in: &subscriptions)
        
        // Set session delegate.
        arView.session.delegate = self
        
        arView.debugOptions = [.showPhysics]

    }


    // Helper method for creating a detection image.
    func makeDetectionImage(named: String, referenceName: String, physicalWidth: CGFloat) -> ARReferenceImage? {
        guard let targetImage = UIImage(named: named)?.cgImage else {
            print("❗️ Error loading target image:", named)
            return nil
        }

        let arReferenceImage  = ARReferenceImage(targetImage, orientation: .up, physicalWidth: physicalWidth)
        arReferenceImage.name = referenceName

        return arReferenceImage
    }


    // Process UI signals.
    func processUISignal(_ signal: ViewModel.UISignal) {
        switch signal {
        case .reset:
            print("👇 Did press reset button")
            
            // Reset scene and all anchors.
            arView.scene.anchors.removeAll()
            subscriptions.removeAll()
            
            setupScene()
            setupEntities()
        }
    }


    // Called when an anchor is added to scene.
    func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
        // Handle image anchors.
        anchors.compactMap { $0 as? ARImageAnchor }.forEach {
            // Grab reference image name.
            guard let referenceImageName = $0.referenceImage.name else { return }

            // Create anchor and place at image location.
            let anchorEntity = AnchorEntity(world: $0.transform)
            arView.scene.addAnchor(anchorEntity)
            
            //If any of the reference images are detected
            //setup scene
            
            setupSceneEntities(anchorEntity: anchorEntity)
            // Setup logic based on reference image.
//            if referenceImageName == "IMAGE_ALPHA" {
//                setupEntitiesForImageAlpha(anchorEntity: anchorEntity)
//            } else if referenceImageName == "IMAGE_BETA" {
//                setupEntitiesForImageBeta(anchorEntity: anchorEntity)
//            }
        }
    }


    // Setup method for non image anchor entities.
    func setupEntities() {
        // Create an anchor at scene origin.
        originAnchor = AnchorEntity(world: .zero)
        arView.scene.addAnchor(originAnchor)

        //TODO: Yellow cube for origin anchor.
        //originAnchor.addChild(makeBoxMarker(color: .yellow))
        
        // Add pov entity that follows the camera.
        pov = AnchorEntity(.camera)
        arView.scene.addAnchor(pov)
    }


    // IMPORTANT: Attach to anchor entity. Called when image target is found.

    func setupSceneEntities(anchorEntity: AnchorEntity) {
        // Add red box to alpha anchor.
        // TODO: remove once all models in place
        let marker = makeBoxMarker(color: .red)
        anchorEntity.addChild(marker)

        let landingStone = setupLandingRockEntity();
        anchorEntity.addChild(landingStone)
        
        //let larva = setupLarvaEntity();
        //anchorEntity.addChiƒld(larva);
        
        for ind in 0..<startingLava {
            let name = "larva-\(ind)"
            let larva = LarvaEntity(name: name, ind: Float(ind))
            arView.installGestures([.translation,], for: larva)
            
            anchorEntity.addChild(larva)
            allLarva.append(larva)
        }
 
    }
    
    //Setup Entities:
    func setupLandingRockEntity() -> Entity{
        let stone = try! Entity.loadModel(named: "stone-test.usdz")
        let stoneMesh = ShapeResource.generateConvex(from: stone.model!.mesh)
        stone.components[CollisionComponent.self] = CollisionComponent(shapes: [stoneMesh], mode: .default, filter: .default)
        //Positioning and scale:
        stone.scale = [0.0075,0.0075,0.0075];
        stone.name = "landingStone";
        return stone;
    }
    // OLD
    func setupLarvaEntity() -> Entity{
        let larva = try! Entity.loadModel(named: "stone-test-larva.usdz")
        let larvaMesh = ShapeResource.generateConvex(from: larva.model!.mesh)
        larva.components[CollisionComponent.self] = CollisionComponent(shapes: [larvaMesh], mode: .default, filter: .default)
        //Positioning and scale:
        larva.scale = [0.0025,0.0025,0.0025];
        larva.position.x = 0.07;
        arView.installGestures([.translation,], for: larva)
        return larva;
    }
    
    // Render loop.
    func renderLoop() {
//        print(camera.orientation)
        //TODO: print camera rotation?
        print(self.pov.transform.rotation)
        print(self.pov.transform.translation)

        print(self.cameraTransform.translation.x)
        print(self.cameraTransform.rotation)
        
        let testCameraX = self.cameraTransform.translation.x
        let originAnchorX = self.originAnchor.position.x
//        let testDist = distance(<#T##x: SIMD2<Float>##SIMD2<Float>#>, <#T##y: SIMD2<Float>##SIMD2<Float>#>)(testCameraX, originAnchorX)
//        print(distance(, self.originAnchor.position)
        
    }

    // Helper method for making box to mark anchor position.
    func makeBoxMarker(color: UIColor) -> Entity {
        let boxMesh   = MeshResource.generateBox(size: 0.025, cornerRadius: 0.002)
        let material  = SimpleMaterial(color: color, isMetallic: false)
        return ModelEntity(mesh: boxMesh, materials: [material])
    }
    
    //UNUSED
    func setupEntitiesForImageBeta(anchorEntity: AnchorEntity) {
        // Add green marker to beta anchor.
        let marker = makeBoxMarker(color: .green)
        anchorEntity.addChild(marker)

    }
}


class LarvaEntity: Entity, HasModel, HasCollision  {
    var model: ModelEntity
    //var startingXPos = Float(0.07)
//    var startingYPos = Float(0.00015)
    
    
     init(name: String, ind: Float) {

        let tmodel = try! Entity.loadModel(named: "stone-test-larva.usdz")
        let larvaMesh = ShapeResource.generateConvex(from: tmodel.model!.mesh)
        model = tmodel;
        super.init()
        // Set transform:
         self.model.name = name
         self.position.x = 0.07
         if(Int(ind).isMultiple(of: 2)){
             self.position.x = -0.07;
         }
         
//        self.model.orientation *= simd_quatf(angle: -(Float.pi)/2, axis: [1, 0, 0])
//        self.model.orientation *= simd_quatf(angle: -(Float.pi)/2, axis: [0, 1, 0])

        self.model.scale = [0.0025,0.0025,0.0025];
         self.model.components[CollisionComponent.self] = CollisionComponent(shapes: [larvaMesh], mode: .default, filter: .default)

        self.addChild(model)
    }
    
    required init() {
            fatalError("init() has not been implemented")
   }
    func handleAttachingToStone(){
        //Snap position?
        // TODO: Snap position. Ensure that the larva is in FRONT of the rock (ie change the Z position too)
        
        //turn off collision
        self.model.components[CollisionComponent.self] = nil;
        
    }
    
}
