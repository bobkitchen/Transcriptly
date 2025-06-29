-- Transcriptly Phase 7 - AI Providers Schema Migration
-- Execute on Supabase dashboard: SQL Editor

-- Add provider usage tracking table
CREATE TABLE IF NOT EXISTS provider_usage (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    provider_name TEXT NOT NULL,
    service_type TEXT NOT NULL, -- transcription, refinement, tts
    model_name TEXT,
    request_count INTEGER DEFAULT 1,
    date DATE DEFAULT CURRENT_DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, provider_name, service_type, model_name, date)
);

-- Add provider preferences table
CREATE TABLE IF NOT EXISTS provider_preferences (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    transcription_provider TEXT DEFAULT 'apple',
    transcription_model TEXT,
    refinement_provider TEXT DEFAULT 'apple',
    refinement_model TEXT,
    tts_provider TEXT DEFAULT 'apple',
    tts_model TEXT,
    use_fallback_hierarchy BOOLEAN DEFAULT TRUE,
    prefer_local_processing BOOLEAN DEFAULT TRUE,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_provider_usage_user_date ON provider_usage(user_id, date DESC);
CREATE INDEX IF NOT EXISTS idx_provider_preferences_user ON provider_preferences(user_id);

-- Enable RLS
ALTER TABLE provider_usage ENABLE ROW LEVEL SECURITY;
ALTER TABLE provider_preferences ENABLE ROW LEVEL SECURITY;

-- RLS policies
CREATE POLICY IF NOT EXISTS "Users can manage own provider usage" ON provider_usage
    FOR ALL USING (auth.uid() = user_id);

CREATE POLICY IF NOT EXISTS "Users can manage own provider preferences" ON provider_preferences
    FOR ALL USING (auth.uid() = user_id);