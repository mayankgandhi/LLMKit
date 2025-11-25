//
//  ParsedPrescription.swift
//  LLMKit
//
//  Created by Mayank Gandhi on 08/09/25.
//  Copyright © 2025 m. All rights reserved.
//

//
//  ParsedPrescription.swift
//  Walnut
//
//  Created by Mayank Gandhi on 11/07/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation
import LLMKit

struct ParsedPrescription: ParseableModel {
    
    static var parseDefinition: String {
    ""
    }

    struct Medication: Codable {
        var id: UUID
        var name: String
        var frequency: [MedicationFrequencyData]?
        var duration: MedicationDurationData
        var dosage: String?
        var instructions: String?
    }
    
    // Metadata
    var dateIssued: Date
    var doctorName: String?
    var facilityName: String?
    
    var followUpDate: Date?
    var followUpTests: [String]
    
    var notes: String?
    
    var medications: [Medication]
    static var jsonSchema: OpenAIJSONSchema {
        OpenAIJSONSchema(
            properties: [
                "dateIssued": [
                    "type": "string",
                    "format": "date-time",
                    "description": "Date when the prescription was issued (ISO8601 format)"
                ],
                "medications": [
                    "type": "array",
                    "items": [
                        "type": "object",
                        "properties": [
                            "id": [
                                "type": "string",
                                "format": "uuid",
                                "description": "Unique identifier for the medication"
                            ],
                            "name": [
                                "type": "string",
                                "description": "Name of the medication"
                            ],
                            "dosage": [
                                "anyOf": [
                                    ["type": "string"],
                                    ["type": "null"]
                                ],
                                "description": "Overall dosage information (e.g., '500mg', '2 tablets')"
                            ],
                            "instructions": [
                                "anyOf": [
                                    ["type": "string"],
                                    ["type": "null"]
                                ],
                                "description": "Special instructions for the medication"
                            ],
                            "duration": [
                                "type": "object",
                                "required": ["type"],
                                "anyOf": [
                                    [
                                        "properties": [
                                            "type": [
                                                "type": "string",
                                                "enum": ["days", "weeks", "months"]
                                            ],
                                            "value": [
                                                "type": "integer",
                                                "description": "Numeric value for duration"
                                            ]
                                        ],
                                        "required": ["type", "value"],
                                        "additionalProperties": false
                                    ],
                                    [
                                        "properties": [
                                            "type": [
                                                "type": "string",
                                                "const": "untilFollowUp"
                                            ],
                                            "date": [
                                                "type": "string",
                                                "format": "date-time",
                                                "description": "Follow-up date in ISO 8601 format"
                                            ]
                                        ],
                                        "required": ["type", "date"],
                                        "additionalProperties": false
                                    ],
                                    [
                                        "properties": [
                                            "type": [
                                                "type": "string",
                                                "enum": ["ongoing", "asNeeded"]
                                            ]
                                        ],
                                        "required": ["type"],
                                        "additionalProperties": false
                                    ]
                                ]
                            ],
                            "frequency": [
                                "type": "object",
                                "required": ["type"],
                                "anyOf": [
                                    [
                                        "properties": [
                                            "type": [
                                                "type": "string",
                                                "const": "daily"
                                            ],
                                            "times": [
                                                "type": "array",
                                                "description": "Array of specific times for daily medication",
                                                "items": [
                                                    "type": "object",
                                                    "required": ["hour", "minute"],
                                                    "additionalProperties": false,
                                                    "properties": [
                                                        "hour": [
                                                            "type": "integer",
                                                            "description": "Hour component (0-23)"
                                                        ],
                                                        "minute": [
                                                            "type": "integer",
                                                            "description": "Minute component (0-59)"
                                                        ],
                                                        "second": [
                                                            "type": "integer",
                                                            "description": "Second component (0-59)"
                                                        ]
                                                    ]
                                                ]
                                            ]
                                        ],
                                        "required": ["type", "times"],
                                        "additionalProperties": false
                                    ],
                                    [
                                        "properties": [
                                            "type": [
                                                "type": "string",
                                                "const": "hourly"
                                            ],
                                            "interval": [
                                                "type": "integer",
                                                "description": "Hour interval for medication"
                                            ],
                                            "startTime": [
                                                "type": "object",
                                                "required": ["hour", "minute"],
                                                "additionalProperties": false,
                                                "description": "Starting time for hourly intervals",
                                                "properties": [
                                                    "hour": [
                                                        "type": "integer",
                                                        "description": "Starting hour component (0-23)"
                                                    ],
                                                    "minute": [
                                                        "type": "integer",
                                                        "description": "Starting minute component (0-59)"
                                                    ],
                                                    "second": [
                                                        "type": "integer",
                                                        "description": "Starting second component (0-59)"
                                                    ]
                                                ]
                                            ]
                                        ],
                                        "required": ["type", "interval"],
                                        "additionalProperties": false
                                    ],
                                    [
                                        "properties": [
                                            "type": [
                                                "type": "string",
                                                "enum": ["weekly", "biweekly"]
                                            ],
                                            "dayOfWeek": [
                                                "type": "string",
                                                "enum": ["monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"],
                                                "description": "Day of the week"
                                            ],
                                            "time": [
                                                "type": "object",
                                                "required": ["hour", "minute"],
                                                "additionalProperties": false,
                                                "description": "Specific time of day",
                                                "properties": [
                                                    "hour": [
                                                        "type": "integer",
                                                        "description": "Hour component (0-23)"
                                                    ],
                                                    "minute": [
                                                        "type": "integer",
                                                        "description": "Minute component (0-59)"
                                                    ],
                                                    "second": [
                                                        "type": "integer",
                                                        "description": "Second component (0-59)"
                                                    ]
                                                ]
                                            ]
                                        ],
                                        "required": ["type", "dayOfWeek", "time"],
                                        "additionalProperties": false
                                    ],
                                    [
                                        "properties": [
                                            "type": [
                                                "type": "string",
                                                "const": "monthly"
                                            ],
                                            "dayOfMonth": [
                                                "type": "integer",
                                                "description": "Day of the month (1-31)"
                                            ],
                                            "time": [
                                                "type": "object",
                                                "required": ["hour", "minute"],
                                                "additionalProperties": false,
                                                "description": "Specific time of day",
                                                "properties": [
                                                    "hour": [
                                                        "type": "integer",
                                                        "description": "Hour component (0-23)"
                                                    ],
                                                    "minute": [
                                                        "type": "integer",
                                                        "description": "Minute component (0-59)"
                                                    ],
                                                    "second": [
                                                        "type": "integer",
                                                        "description": "Second component (0-59)"
                                                    ]
                                                ]
                                            ]
                                        ],
                                        "required": ["type", "dayOfMonth", "time"],
                                        "additionalProperties": false
                                    ],
                                    [
                                        "properties": [
                                            "type": [
                                                "type": "string",
                                                "const": "mealBased"
                                            ],
                                            "mealTime": [
                                                "type": "string",
                                                "enum": ["breakfast", "lunch", "dinner", "bedtime"],
                                                "description": "Meal reference point"
                                            ],
                                            "medicationTime": [
                                                "type": "string",
                                                "enum": ["before", "after"],
                                                "description": "Timing relative to meal"
                                            ]
                                        ],
                                        "required": ["type", "mealTime"],
                                        "additionalProperties": false
                                    ]
                                ]
                            ]
                        ],
                        "required": ["id", "name"],
                        "additionalProperties": false
                    ]
                ],
                "doctorName": [
                    "anyOf": [
                        ["type": "string"],
                        ["type": "null"]
                    ],
                    "description": "Name of the prescribing doctor"
                ],
                "facilityName": [
                    "anyOf": [
                        ["type": "string"],
                        ["type": "null"]
                    ],
                    "description": "Name of the medical facility"
                ],
                "notes": [
                    "anyOf": [
                        ["type": "string"],
                        ["type": "null"]
                    ],
                    "description": "Additional notes or instructions"
                ],
                "followUpDate": [
                    "anyOf": [
                        [
                            "type": "string",
                            "format": "date-time"
                        ],
                        ["type": "null"]
                    ],
                    "description": "Date for follow-up appointment (ISO8601 format)"
                ],
                "followUpTests": [
                    "type": "array",
                    "items": [
                        "type": "string"
                    ],
                    "description": "List of follow-up tests recommended"
                ]
            ],
            required: ["dateIssued", "medications"],
            additionalProperties: false
        )
    }
    
    static var tool: LLMKit.ClaudeTool {
        LLMKit.ClaudeTool(
            name: "parse_prescription",
            description: "Parse a prescription document and extract structured medication data",
            inputSchema: ClaudeInputSchema(
                type: "object",
                properties: jsonSchema.properties,
                required: jsonSchema.required
            )
        )
    }
    
    static var toolChoice: LLMKit.ToolChoice {
        LLMKit.ToolChoice(
            type: "tool",
            name: "parse_prescription"
        )
    }
    
}

// MARK: - MedicationFrequency Struct
struct MedicationFrequencyData: Codable, Hashable {
    let type: FrequencyType
    let times: [DateComponents]?
    let interval: Int?
    let startTime: DateComponents?
    let dayOfWeek: Weekday?
    let dayOfMonth: Int?
    let time: DateComponents?
    let mealTime: MealTime?
    let medicationTime: MedicationTime?
    
    enum FrequencyType: String, Codable, CaseIterable {
        case daily, hourly, weekly, biweekly, monthly, mealBased
    }
    
}

enum MealTime: String, Codable, CaseIterable, CustomStringConvertible {
    case breakfast, lunch, dinner, bedtime
    
    var icon: String {
        switch self {
            case .breakfast:
                "sunrise"
            case .lunch:
                "sun.max"
            case .dinner:
                "sunset"
            case .bedtime:
                "moon"
        }
    }
    
    var iconString: String {
        switch self {
            case .breakfast:
                "sunrise"
            case .lunch:
                "sun.max"
            case .dinner:
                "sunset"
            case .bedtime:
                "night"
        }
    }
    
    var displayName: String {
        switch self {
            case .breakfast:
                "Breakfast"
            case .lunch:
                "Lunch"
            case .dinner:
                "Dinner"
            case .bedtime:
                "Bedtime"
        }
    }
    
    var description: String {
        return displayName
    }
    
}

enum MedicationTime: String, Codable, CaseIterable, CustomStringConvertible {
    case before, after
    
    var icon: String {
        switch self {
            case .before:
                ""
            case .after:
                ".fill"
        }
    }
    
    var displayName: String {
        switch self {
            case .before:
                return "Before"
            case .after:
                return "After"
        }
    }
    
    var description: String {
        return displayName
    }
}
//
//  MedicationDurationData.swift
//  Walnut
//
//  Created by Mayank Gandhi on 06/09/25.
//  Copyright © 2025 m. All rights reserved.
//

import Foundation
import LLMKit

// MARK: - MedicationDuration Struct
struct MedicationDurationData: Codable, Hashable {
    
    let type: DurationType
    let value: Int?
    let date: Date?
    
    enum DurationType: String, Codable, CaseIterable {
        case days, weeks, months, ongoing, asNeeded, untilFollowUp
    }
}

enum Weekday: Int, Codable, CaseIterable, CustomStringConvertible {
    case sunday = 1, monday, tuesday, wednesday, thursday, friday, saturday
    
    var displayName: String {
        switch self {
            case .sunday: return "Sunday"
            case .monday: return "Monday"
            case .tuesday: return "Tuesday"
            case .wednesday: return "Wednesday"
            case .thursday: return "Thursday"
            case .friday: return "Friday"
            case .saturday: return "Saturday"
        }
    }
    
    var description: String {
        return displayName
    }
}
