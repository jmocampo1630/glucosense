# Tags Feature Documentation

## Overview
The tags feature allows users to add multiple tags to each glucose record for better organization and categorization. This feature has been added to improve record management and enable users to categorize their glucose readings with custom labels.

## Features Added

### 1. GlucoseRecord Model Updates
- Added `tags` field as `List<String>` to the GlucoseRecord model
- Updated `fromJson` and `toJson` methods to handle tags serialization
- Tags are optional and default to an empty list

### 2. New Widgets

#### TagsInputWidget
- Interactive widget for adding and managing tags
- Features:
  - Add tags by typing and pressing Enter
  - Add tags by clicking the add button
  - Remove tags by clicking the X on each tag chip
  - Displays existing tags as colored chips
  - Customizable hint text

#### TagsDisplayWidget
- Read-only widget for displaying tags
- Features:
  - Shows tags as colored chips
  - Customizable font size, background color, and text color
  - Compact design suitable for lists and detail views
  - Automatically hides when no tags are present

### 3. UI Integration

#### Scan Glucose Record Modal
- Added tags input section after the notes field
- Users can add multiple tags when saving a glucose record
- Tags are included in the updated record when submitted

#### Glucose Level Detail Page
- Added tags display section showing all tags for a record
- Only appears when tags are present
- Uses consistent styling with notes and recommendations sections

#### Patient Record List
- Tags are displayed in the list items beneath the date
- Compact display suitable for the list format
- Only shows when tags are present to save space

## Usage Examples

### Adding Tags
1. When scanning a glucose record, users can add tags like:
   - "before meal"
   - "after exercise"
   - "morning"
   - "medication"
   - "stress"

### Viewing Tags
- Tags appear as colored chips in various parts of the app
- In the detail view, tags have their own section with an icon
- In list views, tags appear compactly below other information

## Technical Implementation

### File Changes
1. `lib/models/glucose_record.model.dart` - Added tags field and JSON serialization
2. `lib/widgets/tags_input_widget.dart` - New interactive tags input widget
3. `lib/widgets/tags_display_widget.dart` - New read-only tags display widget
4. `lib/modals/scan_glucose_record_modal.dart` - Added tags input functionality
5. `lib/pages/glucose_level_detail.dart` - Added tags display section
6. `lib/pages/patient_record_page.dart` - Added tags to list items
7. `lib/services/color_generator.services.dart` - Updated GlucoseRecord creation

### Database Compatibility
- The tags field is properly serialized in the toJson method
- The fromJson method handles missing tags field for backward compatibility
- Existing records without tags will display empty tag lists

## Future Enhancements
Potential improvements that could be added:
- Tag suggestions based on frequently used tags
- Tag-based filtering and search functionality
- Tag categories or color coding
- Export functionality including tag data
- Analytics based on tag usage
