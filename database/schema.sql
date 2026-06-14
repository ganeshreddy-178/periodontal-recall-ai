-- ============================================================
-- Periodontal Recall AI - Complete MySQL Database Schema
-- ============================================================

CREATE DATABASE IF NOT EXISTS periodontal_recall_ai
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE periodontal_recall_ai;

-- ============================================================
-- Table: users
-- ============================================================
CREATE TABLE IF NOT EXISTS users (
    id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
    full_name     VARCHAR(120)     NOT NULL,
    email         VARCHAR(180)     NOT NULL UNIQUE,
    password_hash VARCHAR(255)     NOT NULL,
    role          ENUM('admin','dentist','staff') NOT NULL DEFAULT 'dentist',
    clinic_name   VARCHAR(200),
    phone         VARCHAR(20),
    avatar_url    VARCHAR(500),
    is_active     TINYINT(1)       NOT NULL DEFAULT 1,
    last_login_at DATETIME,
    created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_users_email (email),
    INDEX idx_users_role  (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Table: patients
-- ============================================================
CREATE TABLE IF NOT EXISTS patients (
    id                       INT UNSIGNED   NOT NULL AUTO_INCREMENT,
    user_id                  INT UNSIGNED   NOT NULL,
    first_name               VARCHAR(80)    NOT NULL,
    last_name                VARCHAR(80)    NOT NULL,
    date_of_birth            DATE           NOT NULL,
    gender                   ENUM('male','female','other') NOT NULL,
    phone                    VARCHAR(20),
    email                    VARCHAR(180),
    address                  TEXT,
    smoking_status           ENUM('never','former','current') NOT NULL DEFAULT 'never',
    diabetes_status          ENUM('none','type1','type2','prediabetic') NOT NULL DEFAULT 'none',
    family_history           TINYINT(1)     NOT NULL DEFAULT 0,
    previous_periodontal     TINYINT(1)     NOT NULL DEFAULT 0,
    additional_risk_factors  TEXT,
    notes                    TEXT,
    is_active                TINYINT(1)     NOT NULL DEFAULT 1,
    created_at               DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at               DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY fk_patients_user (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_patients_user    (user_id),
    INDEX idx_patients_name    (last_name, first_name),
    INDEX idx_patients_dob     (date_of_birth)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Table: predictions
-- ============================================================
CREATE TABLE IF NOT EXISTS predictions (
    id                    INT UNSIGNED        NOT NULL AUTO_INCREMENT,
    patient_id            INT UNSIGNED        NOT NULL,
    user_id               INT UNSIGNED        NOT NULL,
    -- Clinical parameters
    age                   TINYINT UNSIGNED    NOT NULL,
    plaque_index          DECIMAL(4,2)        NOT NULL COMMENT '0-3 scale',
    bleeding_on_probing   DECIMAL(5,2)        NOT NULL COMMENT 'percentage 0-100',
    pocket_depth          DECIMAL(4,2)        NOT NULL COMMENT 'mm average',
    attachment_loss       DECIMAL(4,2)        NOT NULL COMMENT 'mm average',
    oral_hygiene_score    DECIMAL(4,2)        NOT NULL COMMENT '0-10 scale',
    -- Image data
    image_path            VARCHAR(500),
    image_filename        VARCHAR(255),
    -- AI results
    cnn_severity          ENUM('healthy','mild','moderate','severe'),
    cnn_confidence        DECIMAL(5,2)        COMMENT 'percentage 0-100',
    clinical_risk_score   DECIMAL(5,2)        COMMENT '0-100',
    clinical_risk_level   ENUM('low','moderate','high'),
    final_severity        ENUM('healthy','mild','moderate','severe') NOT NULL,
    final_risk_level      ENUM('low','moderate','high')              NOT NULL,
    final_confidence      DECIMAL(5,2),
    -- Recall
    recall_interval_min   TINYINT UNSIGNED    NOT NULL COMMENT 'months',
    recall_interval_max   TINYINT UNSIGNED    NOT NULL COMMENT 'months',
    recommendations       TEXT,
    -- Meta
    model_version_id      INT UNSIGNED,
    processing_time_ms    INT UNSIGNED,
    created_at            DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY fk_pred_patient (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
    FOREIGN KEY fk_pred_user    (user_id)    REFERENCES users(id)    ON DELETE CASCADE,
    INDEX idx_pred_patient    (patient_id),
    INDEX idx_pred_user       (user_id),
    INDEX idx_pred_severity   (final_severity),
    INDEX idx_pred_created    (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Table: recall_reminders
-- ============================================================
CREATE TABLE IF NOT EXISTS recall_reminders (
    id             INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    patient_id     INT UNSIGNED  NOT NULL,
    prediction_id  INT UNSIGNED  NOT NULL,
    due_date       DATE          NOT NULL,
    status         ENUM('pending','sent','acknowledged','overdue') NOT NULL DEFAULT 'pending',
    notes          TEXT,
    sent_at        DATETIME,
    created_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY fk_reminder_patient    (patient_id)    REFERENCES patients(id)    ON DELETE CASCADE,
    FOREIGN KEY fk_reminder_prediction (prediction_id) REFERENCES predictions(id) ON DELETE CASCADE,
    INDEX idx_reminder_patient  (patient_id),
    INDEX idx_reminder_due      (due_date),
    INDEX idx_reminder_status   (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Table: model_versions
-- ============================================================
CREATE TABLE IF NOT EXISTS model_versions (
    id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    version_tag   VARCHAR(30)   NOT NULL UNIQUE COMMENT 'e.g. v1.0.0',
    model_path    VARCHAR(500)  NOT NULL,
    accuracy      DECIMAL(5,2),
    auc_score     DECIMAL(5,4),
    description   TEXT,
    is_active     TINYINT(1)    NOT NULL DEFAULT 0,
    trained_at    DATETIME,
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_mv_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Table: audit_logs
-- ============================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
    user_id     INT UNSIGNED,
    action      VARCHAR(100)    NOT NULL,
    entity      VARCHAR(60),
    entity_id   INT UNSIGNED,
    ip_address  VARCHAR(45),
    user_agent  VARCHAR(500),
    details     JSON,
    created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    FOREIGN KEY fk_audit_user (user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_audit_user   (user_id),
    INDEX idx_audit_action (action),
    INDEX idx_audit_entity (entity, entity_id),
    INDEX idx_audit_time   (created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ============================================================
-- Seed: default model version record
-- ============================================================
INSERT INTO model_versions (version_tag, model_path, accuracy, auc_score, description, is_active, trained_at)
VALUES ('v1.0.0', '/app/ai_module/models_saved/periodontal_cnn_model.h5',
        95.30, 0.9870,
        'VGG16 transfer-learning CNN trained on periodontal image dataset',
        1, NOW());
