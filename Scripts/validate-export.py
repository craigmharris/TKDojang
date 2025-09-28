#!/usr/bin/env python3

"""
Export/Import Validation Script for TKDojang
Validates JSON structure and data integrity of exported profiles
"""

import json
import sys
from datetime import datetime
from typing import Dict, Any, List

def validate_uuid(uuid_str: str) -> bool:
    """Validate UUID format"""
    try:
        from uuid import UUID
        UUID(uuid_str)
        return True
    except ValueError:
        return False

def validate_iso_date(date_str: str) -> bool:
    """Validate ISO8601 date format"""
    try:
        datetime.fromisoformat(date_str.replace('Z', '+00:00'))
        return True
    except ValueError:
        return False

def validate_profile(profile: Dict[str, Any]) -> List[str]:
    """Validate a single profile structure"""
    errors = []
    
    # Required fields
    required_fields = [
        'id', 'name', 'avatar', 'colorTheme', 'currentBeltLevel',
        'learningMode', 'createdAt', 'lastActiveAt', 'totalStudyTime',
        'dailyStudyGoal', 'streakDays', 'totalFlashcardsSeen',
        'totalTestsTaken', 'totalPatternsLearned', 'terminologyProgress',
        'patternProgress', 'studySessions', 'stepSparringProgress',
        'gradingHistory', 'exportedAt', 'appVersion', 'exportVersion'
    ]
    
    for field in required_fields:
        if field not in profile:
            errors.append(f"Missing required field: {field}")
    
    # Validate UUIDs
    if 'id' in profile and not validate_uuid(profile['id']):
        errors.append(f"Invalid UUID format for profile id: {profile['id']}")
    
    # Validate dates
    date_fields = ['createdAt', 'lastActiveAt', 'exportedAt']
    for field in date_fields:
        if field in profile and not validate_iso_date(profile[field]):
            errors.append(f"Invalid date format for {field}: {profile[field]}")
    
    # Validate numeric fields
    numeric_fields = ['totalStudyTime', 'dailyStudyGoal', 'streakDays', 
                     'totalFlashcardsSeen', 'totalTestsTaken', 'totalPatternsLearned']
    for field in numeric_fields:
        if field in profile and not isinstance(profile[field], (int, float)):
            errors.append(f"Field {field} should be numeric: {profile[field]}")
    
    # Validate progress arrays
    progress_fields = ['terminologyProgress', 'patternProgress', 'studySessions', 
                      'stepSparringProgress', 'gradingHistory']
    for field in progress_fields:
        if field in profile and not isinstance(profile[field], list):
            errors.append(f"Field {field} should be an array: {type(profile[field])}")
    
    # Validate terminology progress entries
    if 'terminologyProgress' in profile:
        for i, progress in enumerate(profile['terminologyProgress']):
            if not validate_uuid(progress.get('id', '')):
                errors.append(f"Invalid UUID in terminologyProgress[{i}].id")
            if not validate_uuid(progress.get('terminologyEntryID', '')):
                errors.append(f"Invalid UUID in terminologyProgress[{i}].terminologyEntryID")
            if progress.get('masteryLevel') not in ['learning', 'familiar', 'proficient', 'mastered']:
                errors.append(f"Invalid masteryLevel in terminologyProgress[{i}]: {progress.get('masteryLevel')}")
    
    # Validate study sessions
    if 'studySessions' in profile:
        for i, session in enumerate(profile['studySessions']):
            if not validate_uuid(session.get('id', '')):
                errors.append(f"Invalid UUID in studySessions[{i}].id")
            if session.get('sessionType') not in ['flashcards', 'testing', 'patterns', 'mixed']:
                errors.append(f"Invalid sessionType in studySessions[{i}]: {session.get('sessionType')}")
            if 'accuracy' in session and session['accuracy'] is not None:
                accuracy = session['accuracy']
                if not isinstance(accuracy, (int, float)) or not (0.0 <= accuracy <= 1.0):
                    errors.append(f"Invalid accuracy in studySessions[{i}]: {accuracy}")
    
    return errors

def validate_export_file(filename: str) -> None:
    """Validate an export file"""
    try:
        with open(filename, 'r') as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        print(f"❌ Invalid JSON format: {e}")
        return
    except FileNotFoundError:
        print(f"❌ File not found: {filename}")
        return
    
    print(f"🔍 Validating export file: {filename}")
    
    # Check if it's a single profile or profile container
    if 'profiles' in data:
        # Multiple profiles container
        print(f"📁 Container file with {len(data['profiles'])} profile(s)")
        
        container_errors = []
        if 'exportedAt' not in data:
            container_errors.append("Missing exportedAt in container")
        if 'deviceName' not in data:
            container_errors.append("Missing deviceName in container")
        if 'appVersion' not in data:
            container_errors.append("Missing appVersion in container")
        if 'exportVersion' not in data:
            container_errors.append("Missing exportVersion in container")
        
        if container_errors:
            print("❌ Container validation errors:")
            for error in container_errors:
                print(f"   - {error}")
        else:
            print("✅ Container structure valid")
        
        # Validate each profile
        for i, profile in enumerate(data['profiles']):
            print(f"\n👤 Validating profile {i+1}: {profile.get('name', 'Unknown')}")
            errors = validate_profile(profile)
            if errors:
                print(f"❌ Profile {i+1} validation errors:")
                for error in errors:
                    print(f"   - {error}")
            else:
                print(f"✅ Profile {i+1} structure valid")
    
    else:
        # Single profile
        print(f"👤 Single profile: {data.get('name', 'Unknown')}")
        errors = validate_profile(data)
        if errors:
            print("❌ Profile validation errors:")
            for error in errors:
                print(f"   - {error}")
        else:
            print("✅ Profile structure valid")
    
    print(f"\n🎯 Validation complete for {filename}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 validate-export.py <export-file.json>")
        print("Example: python3 validate-export.py TKDojang_TestUser_2025-08-28_14-30-00.tkdprofile")
        sys.exit(1)
    
    validate_export_file(sys.argv[1])