import QtQuick 2.0
import QtQuick.Layouts 1.1
import Material 0.3
import Material.ListItems 0.1
import "formHelper.js" as FormHelper

Page {
    id:addRecipePage

    signal addIngredient();

    title: isEditing ? qsTr("Edit recipe") : qsTr("Add recipe")

    property bool isEditing: recipeId.length > 0;
    property string recipeId;
    property var ingredients;
    property var formValues: isEditing ? dataManager.getRecipeValuesForForm(recipeId) : null
    onFormValuesChanged: {
        if (ingredients)
        {
            ingredients.clear();
        }
        else
        {
            ingredients = createModel(addRecipePage);
        }


        var valueIngredients = formValues["Ingredients"];
        for (var i = 0; i < valueIngredients.length; ++i)
        {
            ingredients.append(valueIngredients[i]);
        }

    }

    onAddIngredient: {
        pageStack.push(chooseFoodForRecipe)
    }

    Component {
        id: modelComponent
        ListModel {
        }
    }

    function createModel(parent) {
        var newModel = modelComponent.createObject(parent);
        return newModel;
    }

    ChooseFoodAmount {
        id: chooseFoodAmountForRecipe
        onConfirmed: {
            console.log("adding ingredient to recipe confirmed "  + amount)
            if (addRecipePage.ingredients === undefined)
            {
                addRecipePage.ingredients = createModel(addRecipePage)
                console.log("new model: " + addRecipePage.ingredients);
            }

            console.log("Food amount for recipe: " + JSON.stringify(food) + " " + amount);

            addRecipePage.ingredients.append({
                                 "FoodId": food["Id"],
                                 "Amount": amount
                             });
            pageStack.pop();
        }
    }

    ChooseFood {
        id: chooseFoodForRecipe
        title: qsTr("Add food to recipe")
        model: dataManager.food
        onItemSelected: {
            console.log("Adding food to recipe: " + item["Id"])
            chooseFoodAmountForRecipe.food = item;
            pageStack.push(chooseFoodAmountForRecipe);
        }
        onEditItem: {
            addFood.foodId = itemId;
            pageStack.push(addFood);
        }
        onDeleteItem: {
            foodDeleteDialog.foodId = itemId
            foodDeleteDialog.show();
        }
    }

    actions: [
        Action {
            name: qsTr("Done")
            iconName: "action/done"
            enabled: {
                return  title.displayText.length > 0 &&
                        addRecipePage.ingredients !== undefined  &&
                        addRecipePage.ingredients.count > 0
            }
            onTriggered: {
                var data = {};
                data["Name"] = title.displayText;
                var list = [];
                for (var i = 0; i < addRecipePage.ingredients.count; ++i) {
                    var ingredient = addRecipePage.ingredients.get(i);
                    console.log("Added ingredient " + JSON.stringify(ingredient));
                    list.push(ingredient);
                }

                data["Ingredients"] = list;
                if (isEditing) {
                    dataManager.editRecipe(recipeId, data)
                } else {
                    dataManager.addRecipe(data);
                }



                pageStack.pop();
            }
        }

    ]

    ColumnLayout {
        spacing: 0
        anchors {
            left: parent.left
            right: parent.right
        }

        Card {
            anchors {
                left: parent.left
                right: parent.right
            }
            height: dp(80)
            backgroundColor: Palette.colors["deepPurple"]["400"]

            TextField {
                id: title
                focus: !isEditing
                text: formValues ? formValues["Name"] : ""
                anchors {
                    centerIn: parent
                }

                color: Palette.colors["deepPurple"]["200"]

                width: parent.width * 0.9

                floatingLabel: true
                font.pointSize: dp(20)
                placeholderText: qsTr("Title")
            }

        }


        Subheader {
            text: qsTr("Ingredients")
        }



        Card {
            anchors {
                left: parent.left
                right: parent.right
            }

            implicitHeight: recipesLayout.implicitHeight

            ColumnLayout {
                id: recipesLayout
                anchors {
                    left: parent.left
                    right: parent.right
                }

                Repeater {
                    id: repeater
                    model: ingredients
                    delegate: FoodAmountRow {
                        modelItem: repeater.model.get(index);
                        food: {
                            console.log("recipe model item: " + JSON.stringify(modelItem))
                            modelItem ? dataManager.getFoodById(modelItem["FoodId"]) : undefined
                        }
                        onPressAndHold: {
                            deleteIngredientDialog.itemIndex = index;
                            deleteIngredientDialog.show();
                        }
                    }
                }

                Standard {
                    text: qsTr("Add ingredient")
                    iconName: "av/playlist_add"
                    onClicked: addIngredient()
                }
            }

        }

    }

    Dialog {
        property int itemIndex;
        onAccepted: {
            addRecipePage.ingredients.remove(itemIndex)
        }

        id: deleteIngredientDialog
        title: qsTr("Delete item?")
        text: qsTr("Do you really want to delete this item?")
    }

}