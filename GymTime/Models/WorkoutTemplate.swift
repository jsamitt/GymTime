import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    var id: UUID = UUID()
    var name: String = ""
    var subtitle: String = ""
    var order: Int = 0

    @Relationship(deleteRule: .cascade, inverse: \TemplateExercise.template)
    var templateExercises: [TemplateExercise]? = []

    init(name: String, subtitle: String, order: Int = 0) {
        self.name = name
        self.subtitle = subtitle
        self.order = order
    }

    var orderedExercises: [TemplateExercise] {
        (templateExercises ?? []).sorted { $0.order < $1.order }
    }
}

@Model
final class TemplateExercise {
    var id: UUID = UUID()
    var order: Int = 0
    var template: WorkoutTemplate?
    var exercise: Exercise?

    init(template: WorkoutTemplate, exercise: Exercise, order: Int) {
        self.template = template
        self.exercise = exercise
        self.order = order
    }
}
