import SwiftUI

struct Recipe {
    var name: String
    var ingredients: [String]
    var preparationSteps: [String]
    var cookingTime: String
    var servingSize: Int
    var image : String
}

class RecipeViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []

    init() {
        recipes = [
            Recipe(
                name: "Carbonara",
                ingredients: ["Eggs", "Pasta"],
                preparationSteps: ["Boil Pasta", "Add egg"],
                cookingTime: "30 minutes",
                servingSize: 4,
                image: "carbonara"
            ),
            Recipe(
                name: "Meatballs",
                ingredients: ["Minced Veal", "Breadcrumbs"],
                preparationSteps: ["Form meat into ball", "Surround in breadcrumbs"],
                cookingTime: "20 minutes",
                servingSize: 2,
                image: "meatballs"

            ),
        ]
    }

    func updateRecipe(recipe: Recipe) {
        if let index = recipes.firstIndex(where: { $0.name == recipe.name }) {
            recipes[index] = recipe
        }
    }
}


struct RecipeView: View {
    var recipe: Recipe
    
    var body: some View {
        NavigationLink(destination: RecipeDetailsView(recipe: recipe)) {
            VStack {
                Image("\(recipe.image)")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                
                Text(recipe.name)
                    .font(.title)
                    .foregroundColor(.black)
                    .padding()
                
                HStack {
                    NavigationLink(destination: EditRecipeView(recipe: recipe)) {
                        NavigationLink(
                            destination: EditRecipeView(recipe: recipe)) {
                                Label("Edit Recipe", systemImage: "pencil")
                                    .foregroundColor(.black).padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 150))
                                
                            }
                    }
                    
                    Button(action: {
                    }) {
                        Label("Delete", systemImage: "trash")
                            .foregroundColor(.black)
                    }
                }
                Spacer()
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 5)
        }
    }
}

struct RecipeDetailsView: View {
    var recipe: Recipe
    
    var body: some View {
        VStack{
            
            List {
                Image(recipe.image)
                    .resizable()
                    .frame(width: 300, height: 250)
            
                Section(header: Text("Recipe Details")) {
                    Text("Name: \(recipe.name)")
                    Text("Cooking Time: \(recipe.cookingTime)")
                    Text("Serving Size: \(recipe.servingSize)")
                }
                
                Section(header: Text("Ingredients")) {
                    ForEach(recipe.ingredients, id: \.self) { ingredient in
                        Text(ingredient)
                    }
                }
                
                Section(header: Text("Preparation Steps")) {
                    ForEach(recipe.preparationSteps, id: \.self) { step in
                        Text(step)
                    }
                }
            }
            .padding(.top,10)
            .navigationBarTitle(recipe.name)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)  //
            .background(LinearGradient(gradient: Gradient(colors: [Color.brown, Color.white]), startPoint: .top, endPoint: .center).ignoresSafeArea())
    }
}


struct EditRecipeView: View {
   
    @EnvironmentObject var recipeViewModel: RecipeViewModel

    @State private var editedRecipe: Recipe
    var recipe: Recipe
    
    init(recipe: Recipe) {
        self.recipe = recipe
        _editedRecipe = State(initialValue: recipe)
    }
    
    func saveChanges() {
          recipeViewModel.updateRecipe(recipe: editedRecipe)
      }
    
    var body: some View {
        VStack{
            Form {
                Section(header: Text("Recipe Information")) {
                    TextField("Name", text: $editedRecipe.name)
                    TextField("Cooking Time", text: $editedRecipe.cookingTime)
                    Stepper("Serving Size: \(editedRecipe.servingSize)", value: $editedRecipe.servingSize, in: 1...10)
                }
                
                Section(header: Text("Ingredients")) {
                    ForEach(0..<editedRecipe.ingredients.count, id: \.self) { index in
                        TextField("Ingredient \(index + 1)", text: $editedRecipe.ingredients[index])
                    }
                    Button(action: {
                        editedRecipe.ingredients.append("")
                    }) {
                        Text("Add Ingredient")
                    }
                }
                
                Section(header: Text("Preparation Steps")) {
                    ForEach(0..<editedRecipe.preparationSteps.count, id: \.self) { index in
                        TextField("Step \(index + 1)", text: $editedRecipe.preparationSteps[index])
                    }
                    Button(action: {
                        editedRecipe.preparationSteps.append("")
                    }) {
                        Text("Add Step")
                    }
                }
            }.padding(.top,10)
           
        }.frame(maxWidth: .infinity, maxHeight: .infinity)  //
            .background(LinearGradient(gradient: Gradient(colors: [Color.brown, Color.white]), startPoint: .top, endPoint: .center).ignoresSafeArea())
        
        Button(action: {
                        saveChanges()
                    }) {
                        Text("Save Changes")
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
        
        .onAppear {
            editedRecipe = recipe
        }
        .navigationBarTitle("Edit Recipe: \(editedRecipe.name)")
    }
}
struct SearchRecipesView: View {
    @Binding var recipes: [Recipe]
    @Binding var searchText: String
    
    var body: some View {
        VStack {
            
            TextField("Search", text: $searchText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                
            
            ScrollView{
                ForEach(recipes.filter { searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText) }, id: \.name) { recipe in
                    RecipeView(recipe: recipe)
                        .padding()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)  //
            .background(LinearGradient(gradient: Gradient(colors: [Color.brown, Color.white]), startPoint: .top, endPoint: .center).ignoresSafeArea())
        .navigationTitle("Search Recipes")
    }
}


struct AddRecipeView: View {
    @ObservedObject var recipeViewModel: RecipeViewModel
    @Binding var isAddingRecipe: Bool
    @State private var newRecipe: Recipe = Recipe(name: "", ingredients: [], preparationSteps: [], cookingTime: "", servingSize: 1, image: "")
    @State private var selectedImage: Image?

    @State private var addImage = false

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add an image")) {
                    Button(action: {
                        addImage=true
                        openFilePicker()
                                }) {
                                    Text("Select Image")
                                }
                                
                        .fileImporter(isPresented: .constant(addImage), allowedContentTypes: [.image]) { result in
                            do {
                                let fileURL = try result.get()
                                
                                if let image = loadImage(from: fileURL) {
                                    selectedImage = Image(uiImage: image)
                                }
                            } catch {
                                print("Error: \(error)")
                            }
                        }

                        // Display the selected image
                        if let selectedImage = selectedImage {
                            selectedImage
                                .resizable()
                                .frame(width: 200, height: 200)
                        }
                   
                }
                Section(header: Text("Recipe Information")) {
                    TextField("Name", text: $newRecipe.name)
                    TextField("Cooking Time", text: $newRecipe.cookingTime)
                    Stepper("Serving Size: \(newRecipe.servingSize)", value: $newRecipe.servingSize, in: 1...10)
                }

                Section(header: Text("Ingredients")) {
                    ForEach(0..<newRecipe.ingredients.count, id: \.self) { index in
                        TextField("Ingredient \(index + 1)", text: $newRecipe.ingredients[index])
                    }
                    Button(action: {
                        newRecipe.ingredients.append("")
                    }) {
                        Text("Add Ingredient")
                    }
                }

                Section(header: Text("Preparation Steps")) {
                    ForEach(0..<newRecipe.preparationSteps.count, id: \.self) { index in
                        TextField("Step \(index + 1)", text: $newRecipe.preparationSteps[index])
                    }
                    Button(action: {
                        newRecipe.preparationSteps.append("")
                    }) {
                        Text("Add Step")
                    }
                }
                
               
            }
            .navigationBarTitle("Add Recipe")
            .navigationBarItems(trailing:
                Button("Save") {
                    recipeViewModel.recipes.append(newRecipe)
                    isAddingRecipe = false
                }
            )
        }
    }
    
    func loadImage(from fileURL: URL) -> UIImage? {
           do {
               let data = try Data(contentsOf: fileURL)
               return UIImage(data: data)
           } catch {
               print("Error loading image: \(error)")
               return nil
           }
       }

       func openFilePicker() {
           
       }
}





class MenuViewModel: ObservableObject {
    @Published var selectedRecipes: [Recipe] = []

    func addSelectedRecipe(_ recipe: Recipe) {
        if let index = selectedRecipes.firstIndex(where: { $0.name == recipe.name }) {
            print("Recipe \(recipe.name) already exists in selectedRecipes.")
        } else {
            selectedRecipes.append(recipe)
            print("Added recipe \(recipe.name) to selectedRecipes.")
        }
    }

}


struct MenuView: View {
    @State private var searchText = ""
    @ObservedObject var menuViewModel = MenuViewModel()
    @ObservedObject var recipeViewModel = RecipeViewModel()

    var body: some View {
            VStack {
                TextField("Search Meals", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.top,30)
                    
                
                List {
                    ForEach(recipeViewModel.recipes.filter {
                        searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
                    }, id: \.name) { recipe in
                        HStack {
                            Text(recipe.name)
                            Spacer()
                            Button(action: {
                                menuViewModel.addSelectedRecipe(recipe)
                            }) {
                                Text("Add")
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(Color.brown)
                                    .foregroundColor(.white)
                                    .fontWeight(.black)
                                    .cornerRadius(5)
                            }
                        }
                    }
                }
                .listStyle(PlainListStyle())
                
                Text("Meals On The Menu")
                    .font(.title)
                    .foregroundColor(.black)
                    
                    
                    
                
                List(menuViewModel.selectedRecipes, id: \.name) { recipe in
                    Text(recipe.name)
                }
                
                .listStyle(PlainListStyle())
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)  //
                .background(LinearGradient(gradient: Gradient(colors: [Color.brown, Color.white]), startPoint: .top, endPoint: .center).ignoresSafeArea())
            
        }
    }


struct IngredientsView: View {
    @ObservedObject var menuViewModel = MenuViewModel()

    var allSelectedIngredients: [String] {
        var ingredients: [String] = []
        for recipe in menuViewModel.selectedRecipes {
            ingredients.append(contentsOf: recipe.ingredients)
        }
        return ingredients
    }

    var body: some View {
        VStack{
            
                if allSelectedIngredients.isEmpty {
                    Image("ingredients")
                    Text("No ingredients needed!")
                        .font(.title)
                        .foregroundColor(.black)
                        
                    Text("Add Meals to your menu to get the list of ingredients here!")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.top,10)
                } else {
                    Image("ingredients")
                        .resizable()
                        .frame(width: 200,height: 200)
                    
                    Text("Ingredients needed for meals on the menu!")
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding(.top,20)
                        
                    List {
                        ForEach(allSelectedIngredients, id: \.self) { ingredient in
                            Text(ingredient)
                        }
                    }
                    .padding(.top,10)
                    .listStyle(PlainListStyle())
                    
                }
            
        }.frame(maxWidth: .infinity, maxHeight: .infinity)  //
            .background(LinearGradient(gradient: Gradient(colors: [Color.brown, Color.white]), startPoint: .top, endPoint: .center).ignoresSafeArea())
    }
}



struct ContentView: View {
    @ObservedObject var recipeViewModel = RecipeViewModel()
    @StateObject private var menuViewModel = MenuViewModel()
    
    @State private var searchText = ""
    @State private var isAddingRecipe = false
    
    var body: some View {
        VStack {
            TabView {
                NavigationView {
                    VStack{
                        HStack {
                            
                            NavigationLink(
                                destination: SearchRecipesView(recipes: $recipeViewModel.recipes, searchText: $searchText)) {
                                    Label("Search Recipes", systemImage: "magnifyingglass")
                                        .foregroundColor(.black)
                                }.padding(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 0))
                            
                            Button(action: {
                                isAddingRecipe = true
                            }) {
                                Label("Add Recipe", systemImage: "plus.circle")
                                    .foregroundColor(.black)
                                    .frame(width: 200)
                                
                            }
                        }
                        
                        ScrollView {
                            ForEach(recipeViewModel.recipes, id: \.name) { recipe in
                                RecipeView(recipe: recipe)
                                    .padding()
                            }
                        }
                    }
                    .background(LinearGradient(gradient: Gradient(colors: [Color.brown, Color.white]), startPoint: .top,endPoint: .center)
                        .ignoresSafeArea())
                    .navigationTitle("Chef's Best Friend")
                    .sheet(isPresented: $isAddingRecipe) {
                        AddRecipeView(recipeViewModel: recipeViewModel, isAddingRecipe: $isAddingRecipe)
                    }
                }
                
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                    
                }
                .tag(0)
                
                NavigationView {
                    SearchRecipesView(recipes: $recipeViewModel.recipes, searchText: $searchText)
                        .navigationTitle("Search Recipes")
                }
                .tabItem {
                    Label("Search", systemImage: "magnifyingglass")
                }
                .tag(1)
                
                
                NavigationView {
                    IngredientsView(menuViewModel: menuViewModel)
                        .navigationTitle("Ingredients")
                }
                
                
                .tabItem {
                    Label("Ingredients", systemImage: "list.bullet")
                }
                .tag(2)
                
                NavigationView {
                    MenuView(menuViewModel: menuViewModel, recipeViewModel: recipeViewModel)
                        .navigationTitle("Prepare Your Menu")
                }
                
                .tabItem {
                    Label("Menu", systemImage: "book")
                }
                .tag(1)
                
            }
        }
    }
}

#Preview {
    ContentView()
}


