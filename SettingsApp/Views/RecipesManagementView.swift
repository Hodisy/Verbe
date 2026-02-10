import SwiftUI
import UniformTypeIdentifiers

struct RecipesManagementView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var showingEditor = false
    @State private var editingRecipe: Recipe?
    @State private var showingDeleteAllConfirmation = false
    @State private var draggedRecipe: Recipe?

    var body: some View {
        VStack(spacing: 20) {
            HStack {
                SettingsPageTitle("Recipes")
                Spacer()
                Button {
                    editingRecipe = nil
                    showingEditor = true
                } label: {
                    Label("New Recipe", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }

            Divider()

            HStack(spacing: 10) {
                Button("Reload All Recipes") {
                    viewModel.reloadAllRecipes()
                }
                .buttonStyle(.borderedProminent)

                Button("Delete All Recipes", role: .destructive) {
                    showingDeleteAllConfirmation = true
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.customRecipes.isEmpty)
            }

            if viewModel.customRecipes.isEmpty {
                Spacer()
                VStack(spacing: 16) {
                    Image(systemName: "star.slash")
                        .font(.system(size: 48, weight: .light))
                        .foregroundColor(Semantics.textSecondary)
                    Text("No recipes yet")
                        .font(.headline)
                        .foregroundColor(Semantics.textPrimary)
                    Text("Add the default collection to get started.")
                        .font(.subheadline)
                        .foregroundColor(Semantics.textSecondary)
                    Button("Restore Default Recipes") {
                        viewModel.reloadAllRecipes()
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 20) {
                        ForEach(viewModel.customRecipes) { recipe in
                            RecipeBubbleView(recipe: recipe)
                                .onTapGesture {
                                    editingRecipe = recipe
                                    showingEditor = true
                                }
                                .onDrag {
                                    draggedRecipe = recipe
                                    return NSItemProvider(object: NSString(string: recipe.id.uuidString))
                                }
                                .onDrop(
                                    of: [UTType.text],
                                    delegate: RecipeDropDelegate(
                                        destinationItem: recipe,
                                        recipes: viewModel.customRecipes,
                                        draggedItem: $draggedRecipe,
                                        viewModel: viewModel
                                    )
                                )
                                .contextMenu {
                                    Button("Edit") {
                                        editingRecipe = recipe
                                        showingEditor = true
                                    }
                                    Button("Delete", role: .destructive) {
                                        if let index = viewModel.customRecipes.firstIndex(where: { $0.id == recipe.id }) {
                                            viewModel.deleteRecipe(at: index)
                                        }
                                    }
                                }
                        }
                    }
                    .padding()
                }

                Spacer()
            }
        }
        .sheet(isPresented: $showingEditor) {
            RecipeEditorView(
                recipe: editingRecipe,
                viewModel: viewModel,
                isPresented: $showingEditor
            )
        }
        .onDrop(of: [UTType.text], isTargeted: nil) { _ in
            draggedRecipe = nil
            return true
        }
        .confirmationDialog(
            "Delete all recipes?",
            isPresented: $showingDeleteAllConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) {
                viewModel.deleteAllRecipes()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently remove all your recipes.")
        }
    }
}

private struct RecipeDropDelegate: DropDelegate {
    let destinationItem: Recipe
    let recipes: [Recipe]
    @Binding var draggedItem: Recipe?
    let viewModel: SettingsViewModel

    func dropEntered(info: DropInfo) {
        guard let draggedItem,
              draggedItem.id != destinationItem.id,
              let from = recipes.firstIndex(where: { $0.id == draggedItem.id }),
              let to = recipes.firstIndex(where: { $0.id == destinationItem.id }) else {
            return
        }

        if from != to {
            withAnimation {
                viewModel.moveRecipe(
                    from: IndexSet(integer: from),
                    to: to > from ? to + 1 : to
                )
            }
        }
    }

    func performDrop(info: DropInfo) -> Bool {
        draggedItem = nil
        return true
    }
}

struct RecipeBubbleView: View {
    let recipe: Recipe

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: recipe.icon)
                .font(.system(size: 36, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [recipe.glow, recipe.color],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Text(recipe.label)
                .font(.system(.caption, design: .rounded))
                .fontWeight(.medium)
                .foregroundColor(Semantics.textPrimary)
                .lineLimit(1)
        }
        .frame(width: 120, height: 120)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(recipe.color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [recipe.glow.opacity(0.4), recipe.color.opacity(0.4)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: recipe.glow.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
}
