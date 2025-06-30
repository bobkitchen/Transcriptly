-- Transcriptly Phase 3 - Learning System Supabase Schema
-- Run this in Supabase SQL editor
-- Enable RLS (Row Level Security) on all tables

-- Users table (if not exists)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE,
    device_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Learning sessions table
CREATE TABLE learning_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    original_transcription TEXT NOT NULL,
    ai_refinement TEXT NOT NULL,
    user_final_version TEXT NOT NULL,
    refinement_mode TEXT NOT NULL,
    text_length INTEGER NOT NULL,
    learning_type TEXT NOT NULL,
    was_skipped BOOLEAN DEFAULT FALSE,
    device_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT text_length_positive CHECK (text_length > 0)
);

-- Learned patterns table
CREATE TABLE learned_patterns (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    original_phrase TEXT NOT NULL,
    corrected_phrase TEXT NOT NULL,
    occurrence_count INTEGER DEFAULT 1,
    first_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_seen TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    refinement_mode TEXT,
    confidence DECIMAL(3,2) DEFAULT 0.5,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(user_id, original_phrase, corrected_phrase)
);

-- User preferences table
CREATE TABLE user_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    preference_type TEXT NOT NULL,
    value DECIMAL(3,2) NOT NULL,
    sample_count INTEGER DEFAULT 1,
    last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, preference_type),
    CONSTRAINT value_range CHECK (value >= -1 AND value <= 1)
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE learning_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE learned_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_preferences ENABLE ROW LEVEL SECURITY;

-- Create RLS policies
CREATE POLICY "Users can view own data" ON users
    FOR ALL USING (auth.uid() = id);

CREATE POLICY "Users can view own sessions" ON learning_sessions
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own patterns" ON learned_patterns
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own preferences" ON user_preferences
    FOR ALL USING (auth.uid() = user_id);

-- Phase Eight: Read Aloud Tables

-- Documents table for read-aloud documents
CREATE TABLE documents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    original_filename TEXT NOT NULL,
    content TEXT NOT NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_read_at TIMESTAMP WITH TIME ZONE,
    total_read_time INTEGER DEFAULT 0,
    CONSTRAINT content_not_empty CHECK (LENGTH(content) > 0)
);

-- Reading sessions table for read-aloud sessions
CREATE TABLE reading_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    current_sentence_index INTEGER DEFAULT 0,
    is_completed BOOLEAN DEFAULT FALSE,
    progress DECIMAL(5,4) DEFAULT 0.0,
    playback_settings JSONB,
    CONSTRAINT progress_range CHECK (progress >= 0 AND progress <= 1),
    CONSTRAINT sentence_index_positive CHECK (current_sentence_index >= 0)
);

-- Document bookmarks table
CREATE TABLE document_bookmarks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    document_id UUID REFERENCES documents(id) ON DELETE CASCADE,
    sentence_index INTEGER NOT NULL,
    title TEXT NOT NULL,
    note TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    CONSTRAINT sentence_index_positive CHECK (sentence_index >= 0)
);

-- Enable Row Level Security for read-aloud tables
ALTER TABLE documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE reading_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE document_bookmarks ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for read-aloud tables
CREATE POLICY "Users can manage own documents" ON documents
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own reading sessions" ON reading_sessions
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "Users can manage own bookmarks" ON document_bookmarks
    FOR ALL USING (auth.uid() = user_id);

-- Create indexes for performance
CREATE INDEX idx_learning_sessions_user_timestamp ON learning_sessions(user_id, timestamp DESC);
CREATE INDEX idx_patterns_user_active ON learned_patterns(user_id, is_active);
CREATE INDEX idx_patterns_confidence ON learned_patterns(confidence DESC);

-- Read-aloud performance indexes
CREATE INDEX idx_documents_user_created ON documents(user_id, created_at DESC);
CREATE INDEX idx_documents_user_last_read ON documents(user_id, last_read_at DESC NULLS LAST);
CREATE INDEX idx_reading_sessions_user_start ON reading_sessions(user_id, start_time DESC);
CREATE INDEX idx_reading_sessions_document ON reading_sessions(document_id, start_time DESC);
CREATE INDEX idx_bookmarks_document ON document_bookmarks(document_id, sentence_index);