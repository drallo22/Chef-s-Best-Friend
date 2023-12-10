import SwiftUI

struct Recipe: Identifiable, Codable {
    var id: String?
    var name: String
    var ingredients: [String]
    var preparationSteps: [String]
    var cookingTime: String
    var servingSize: Int
    var image: String
    
    var dictionary: [String: Any] {
           return [
               "name": name,
               "ingredients": ingredients,
               "preparationSteps": preparationSteps,
               "cookingTime": cookingTime,
               "servingSize": servingSize,
               "image": image
           ]
       }
}
class RecipeViewModel: ObservableObject {
    @Published var recipes: [Recipe] = []

    private var firestoreAdapter = FirestoreAdapter()

    init() {
        loadRecipes()
    }


    
    func updateRecipe(recipe: Recipe) {
        
        print("Updating recipe with name: \(recipe.name)")
            print("Recipe dictionary: \(recipe.dictionary)")
            firestoreAdapter.updateDocument(collectionName: "recipes", documentId: recipe.name, fields: recipe.dictionary) { error in
                if let error = error {
                    print("Error updating recipe: \(error)")
                } else {
                    print("Recipe updated successfully")
                }
            }
        
        loadRecipes()
        }

     func loadRecipes() {
        firestoreAdapter.getDocuments(collectionName: "recipes") { result in
            switch result {
            case .success(let documents):
                print("Recipes loaded")
                let recipes = documents.compactMap { document in
                    try? document.data(as: Recipe.self)
                    
                }
                self.recipes = recipes
                print(recipes.count)

                
            case .failure(let error):
                print("Error loading recipes: \(error)")
            }
        }
    }
    
    func deleteRecipe(recipe: Recipe) {
            firestoreAdapter.deleteDocument(collectionName: "recipes", documentId: recipe.name) { error in
                if let error = error {
                    print("Error deleting recipe: \(error)")
                } else {
                    // Remove the deleted recipe from the local array
                    self.recipes.removeAll { $0.name == recipe.name }
                    print("Recipe deleted successfully")
                

                }
            }
        }

}


struct RecipeView: View {
    var recipe: Recipe
    @ObservedObject var recipeViewModel: RecipeViewModel // Inject the RecipeViewModel
    
   
    
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
                    
                        NavigationLink(
                            destination: EditRecipeView(recipe: recipe, recipeViewModel: RecipeViewModel())) {
                                Label("Edit Recipe", systemImage: "pencil")
                                    .foregroundColor(.black).padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 150))
                                
                            
                    }
                    
                    Button(action: {
                        
                        recipeViewModel.deleteRecipe(recipe: recipe)

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
    @ObservedObject var recipeViewModel: RecipeViewModel
    @State  var editedRecipe: Recipe
    var recipe: Recipe

    init(recipe: Recipe, recipeViewModel:RecipeViewModel) {
        print("EditRecipeView initialized with recipe: \(recipe.name)")
        self.recipeViewModel = recipeViewModel
        self.recipe = recipe
        _editedRecipe = State(initialValue: recipe)
    }

    func saveChanges() {
        print("Before updateRecipe")
        recipeViewModel.updateRecipe(recipe: editedRecipe)
        recipeViewModel.loadRecipes()
        print("After updateRecipe")
       
    }

    var body: some View {
        NavigationView {
            VStack {
                Form {
                    Section(header: Text("Recipe Information")) {
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
                    Button(action: {
                        saveChanges()
                    }){
                        Text("Save Changes")
                    }
                }
                .navigationBarTitle("Edit Recipe: \(editedRecipe.name)")

            }
        }
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
                    RecipeView(recipe: recipe, recipeViewModel: RecipeViewModel())
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
    @State  var newRecipe: Recipe = Recipe(name: "", ingredients: [], preparationSteps: [], cookingTime: "", servingSize: 1, image: "")


     var firestoreAdapter = FirestoreAdapter()

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Add an image")) {

                        TextField("Image", text: $newRecipe.image)

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
                    addNewRecipeToDatabase()

                    recipeViewModel.recipes.append(newRecipe)

                    isAddingRecipe = false
                }
            )
        }
    }

     func addNewRecipeToDatabase() {

        firestoreAdapter.addDocument(collectionName: "recipes", model: newRecipe) { result in
            switch result {
            case .success(let documentReference):
                print("Document added with ID: \(documentReference.documentID)")
            case .failure(let error):
                print("Error adding document: \(error)")
            }
        }
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
    @ObservedObject  var recipeViewModel = RecipeViewModel()
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
                            Button("Refresh") {
                                            recipeViewModel.loadRecipes()
                                        }
                            ForEach(recipeViewModel.recipes, id: \.name) { recipe in
                                RecipeView(recipe: recipe, recipeViewModel: RecipeViewModel())
                                    .padding()
                            }
                            
                        }.onAppear(){
                            recipeViewModel.loadRecipes()
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
        }.onAppear(){
            recipeViewModel.loadRecipes()

        }
    }
}

#Preview {
    ContentView()
}


