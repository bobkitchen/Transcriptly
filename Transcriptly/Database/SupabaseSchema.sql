-- Transcriptly Phase 3 - Learning System Supabase Schema
-- Create this schema in Supabase dashboard

-- Users table (if not exists)
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE,
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

-- Indexes for performance
CREATE INDEX idx_learning_sessions_user_timestamp ON learning_sessions(user_id, timestamp DESC);
CREATE INDEX idx_patterns_user_active ON learned_patterns(user_id, is_active);
CREATE INDEX idx_patterns_confidence ON learned_patterns(confidence DESC);