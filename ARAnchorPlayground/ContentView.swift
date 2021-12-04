//  Created by Nien Lam on 10/13/21.
// Altered by Pauline & Rajshree

import SwiftUI
import ARKit
import RealityKit
import Combine


// MARK: - Game Constants
//General Constants
let numDiageticImgMaterials = 10
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
    case CREATION
    case GROWTH
    case NAMING
    case SUCCESS
}

enum CoralCommunityState{
    case INSTRUCTIONS
    case FOUND_COMMUNITY
    case JOINED_COMMUNITY
}


// MARK: - View model for handling communication between the UI and ARView.
class ViewModel: ObservableObject {
    
    // App / Game States
    @Published var appMode: AppMode = AppMode.CORAL_COMMUNITY
    @Published var currentIntroState: IntroState =  IntroState.INSTRUCTIONS
    @Published var currentCoralFormationState: CoralFormationState =  CoralFormationState.INTRO
    @Published var currentCoralCommunityState: CoralCommunityState =  CoralCommunityState.INSTRUCTIONS
 
    let uiSignal = PassthroughSubject<UISignal, Never>()

    enum UISignal {
        case reset
        case CoralFormation_Intro_Next
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
                          
                    }
                    else if(viewModel.currentIntroState == IntroState.CORAL_FACTS){}
                }//end of AppMode.Intro
                
                //AppMode.CoralFormation
                else if(viewModel.appMode == AppMode.CORAL_FORMATION){
                    if(viewModel.currentCoralFormationState == CoralFormationState.INTRO){
                        
                        Button {
                            viewModel.uiSignal.send(.CoralFormation_Intro_Next)
                            viewModel.currentCoralFormationState = CoralFormationState.CREATION
                        } label: {
                            Text("Next")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .font(.system(.largeTitle))
                                .foregroundColor(.white)
                        }
                    }
                    else if(viewModel.currentCoralFormationState == CoralFormationState.CREATION){}
                    else if(viewModel.currentCoralFormationState == CoralFormationState.GROWTH){}
                    else if(viewModel.currentCoralFormationState == CoralFormationState.NAMING){}
                    else if(viewModel.currentCoralFormationState == CoralFormationState.SUCCESS){}
                }//End of AppMode.CoralFormation
                
                //AppMode.CORAL_COMMUNITY
                else if(viewModel.appMode == AppMode.CORAL_COMMUNITY){
                    if(viewModel.currentCoralCommunityState == CoralCommunityState.INSTRUCTIONS){}
                    else if(viewModel.currentCoralCommunityState == CoralCommunityState.FOUND_COMMUNITY){}
                    else if(viewModel.currentCoralCommunityState == CoralCommunityState.JOINED_COMMUNITY){}
                }//End of AppMode.CORAL_COMMUNITY
                ARViewContainer(viewModel: viewModel)
            }// end of main else
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
    
    // General Variables
    var parentEntity: Entity?
    var directionalLight: Entity?
    var diageticPlaneMaterial = [RealityKit.Material]()
    var diageticPlane: ModelEntity?
    // Coral Formation Variables
    var allLarva:[LarvaEntity] = []
    var landingStoneEntity: ModelEntity?
   
    // Coral Community Variables
    var isHoldingCoral = false
    var hasTurnedAwayFromCoralChild = false;

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
        
        //TODO: image
        //setupDiageticPlaneImageMaterials();
        
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
                                                   physicalWidth: 0.18) {
            set.insert(detectionImage)
        }

        // Setup target image B.
        if let detectionImage = makeDetectionImage(named: "dino.jpg",
                                                   referenceName: "IMAGE_BETA",
                                                   physicalWidth: 0.19) {
            set.insert(detectionImage)
        }
    
        
        
        // Setup target image C
        if let detectionImage = makeDetectionImage(named: "IMG_1652.HEIC",
                                                   referenceName: "IMAGE_BETA",
                                                   physicalWidth: 0.19) {
            set.insert(detectionImage)
        }
        
        // Setup target image C
        if let detectionImage = makeDetectionImage(named: "IMG_1653.HEIC",
                                                   referenceName: "IMAGE_BETA",
                                                   physicalWidth: 0.19) {
            set.insert(detectionImage)
        }
        
        // Setup target image C
        if let detectionImage = makeDetectionImage(named: "IMG_1654.HEIC",
                                                   referenceName: "IMAGE_BETA",
                                                   physicalWidth: 0.19) {
            set.insert(detectionImage)
        }
        
        
        
        // Setup target image C
        if let detectionImage = makeDetectionImage(named: "IMG_1654.HEIC",
                                                   referenceName: "IMAGE_BETA",
                                                   physicalWidth: 0.19) {
            set.insert(detectionImage)
        }
        
        
        // Setup target image C
        if let detectionImage = makeDetectionImage(named: "IMG_1655.HEIC",
                                                   referenceName: "IMAGE_BETA",
                                                   physicalWidth: 0.19) {
            set.insert(detectionImage)
        }
        
        
        // Setup target image C
        if let detectionImage = makeDetectionImage(named: "IMG_1656.HEIC",
                                                   referenceName: "IMAGE_BETA",
                                                   physicalWidth: 0.19) {
            set.insert(detectionImage)
        }
        
        
        // Setup target image C
        if let detectionImage = makeDetectionImage(named: "IMG_1657.HEIC",
                                                   referenceName: "IMAGE_BETA",
                                                   physicalWidth: 0.19) {
            set.insert(detectionImage)
        }
        
        // Setup target image C
        if let detectionImage = makeDetectionImage(named: "IMG_1658.HEIC",
                                                   referenceName: "IMAGE_BETA",
                                                   physicalWidth: 0.19) {
            set.insert(detectionImage)
        }
        
        // Setup target image C
        if let detectionImage = makeDetectionImage(named: "IMG_1659.HEIC",
                                                   referenceName: "IMAGE_BETA",
                                                   physicalWidth: 0.19) {
            set.insert(detectionImage)
        }
        
        // Setup target image C
        if let detectionImage = makeDetectionImage(named: "IMG_1660.HEIC",
                                                   referenceName: "IMAGE_BETA",
                                                   physicalWidth: 0.19) {
            set.insert(detectionImage)
        }
        
        // Setup target image C
        if let detectionImage = makeDetectionImage(named: "IMG_1661.HEIC",
                                                   referenceName: "IMAGE_BETA",
                                                   physicalWidth: 0.19) {
            set.insert(detectionImage)
        }
        
        // Setup target image C
        if let detectionImage = makeDetectionImage(named: "IMG_1662.HEIC",
                                                   referenceName: "IMAGE_BETA",
                                                   physicalWidth: 0.19) {
            set.insert(detectionImage)
        }
        

        // Add target images to configuration.
        configuration.detectionImages = set
        configuration.maximumNumberOfTrackedImages = 11

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
        
        // MARK: Collision
        arView.scene.subscribe(to: CollisionEvents.Began.self) { [self] event in
            print("💥 Collision with \(event.entityA.name) & \(event.entityB.name)")
            
            
            // Coral Formation
            if(self.viewModel.appMode == AppMode.CORAL_FORMATION && viewModel.currentCoralFormationState == CoralFormationState.CREATION){
        
                for i in 0..<self.allLarva.count{
                                if (event.entityA.name == "larva-\(i)" && event.entityB.name == "landingStone"){
                                    self.allLarva[i].handleAttachingToStone()
                                }
                }
            }
            
            if(self.viewModel.appMode == AppMode.CORAL_COMMUNITY && viewModel.currentCoralCommunityState == CoralCommunityState.FOUND_COMMUNITY ){
                if (event.entityA.name == "myCoral" && event.entityB.name == "worldCoral"){

                //Detect if collision
                }
            
            }
            
        }.store(in: &subscriptions)
        
        // Set session delegate.
        arView.session.delegate = self
        
        // TODO: hide/show physics colliders
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
            break;
        case .CoralFormation_Intro_Next:
            print("Going to Instructions/Interactive");
            //TODO add coral formation
            //self.addCoralFormationEntities(anchorEntity: <#T##AnchorEntity#>)
            
            break;
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
            
            // MARK: Found Tag
            //If any of the reference images are detected, setup parent entity
            parentEntity = makeBoxMarker(color: .green)
//            parentEntity?.transform = Transform.identity
            anchorEntity.addChild(parentEntity!);
            parentEntity?.position.y = 0.8

        }
    }

    func setupDiageticPlaneImageMaterials() {
        for idx in 0 ..< numDiageticImgMaterials {
               var unlitMaterial = UnlitMaterial()
               let imageNamed = "diagetic-material-image\(idx)"
               unlitMaterial.color.texture = UnlitMaterial.Texture.init(try! .load(named: imageNamed))
               unlitMaterial.color.tint    = UIColor.white.withAlphaComponent(0.999999)
               diageticPlaneMaterial.append(unlitMaterial)
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
        
        //Setup main entities
        diageticPlane =   ModelEntity(mesh: .generatePlane(width: 0.5, depth: 0.5), materials: [SimpleMaterial(color: .blue, isMetallic: false)])
        
        //Coral Formation Entities
        landingStoneEntity = setupLandingRockEntity() as! ModelEntity;
        for ind in 0..<startingLava {
            let name = "larva-\(ind)"
            let larva = LarvaEntity(name: name, ind: Float(ind))
            arView.installGestures([.translation,], for: larva)
            allLarva.append(larva)
        }
    }

    //Setup Entities:
    func setupLandingRockEntity() -> ModelEntity{
        let stone = try! Entity.loadModel(named: "stone-test.usdz")
        let stoneMesh = ShapeResource.generateConvex(from: stone.model!.mesh)
        stone.components[CollisionComponent.self] = CollisionComponent(shapes: [stoneMesh], mode: .default, filter: .default)
        //Positioning and scale:
        stone.scale = [0.0075,0.0075,0.0075];
        stone.name = "landingStone";
        return stone;
    }
    
    // MARK: Attach to anchor entity,
    // Set certain entities to false
    func addCoralFormationEntities(anchorEntity: AnchorEntity) {
         // TODO: remove once all models in place
        let marker = makeBoxMarker(color: .red)
        anchorEntity.addChild(marker)
        
        // Coral Formation
        anchorEntity.addChild(landingStoneEntity!)
        for larva in allLarva {
            anchorEntity.addChild(larva)
        }
        // Coral Community
    }
    
    func addCoralCommunityEntities() {
        print("coral community");
    }
    
    // Render loop.
    func renderLoop() {
        print("rotation y")
        print(self.cameraTransform.rotation.vector.y)
        let currCameraRotationY = self.cameraTransform.rotation.vector.y
        
        
        //Animate Coral Growing Timer Gif
        if(self.viewModel.appMode == AppMode.CORAL_FORMATION && self.viewModel.currentCoralFormationState == CoralFormationState.GROWTH){
            print("growing coral");
        }
        
        //Coral Community - Drag Your Coral Pointer Gif
        if(self.viewModel.appMode == AppMode.CORAL_COMMUNITY && self.viewModel.currentCoralCommunityState == CoralCommunityState.INSTRUCTIONS){
            print("growing coral");
        }
    }

    // Helper method for making box to mark anchor position.
    func makeBoxMarker(color: UIColor) -> Entity {
        let boxMesh   = MeshResource.generateBox(size: 0.025, cornerRadius: 0.002)
        let material  = SimpleMaterial(color: color, isMetallic: false)
        return ModelEntity(mesh: boxMesh, materials: [material])
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
        // TODO: Snap position. Ensure that the larva is in FRONT of the rock (ie change the Z position too)/
        self.model.position.z += 0.1;
        
        //turn off collision
        self.model.components[CollisionComponent.self] = nil;
        
    }
    
}
