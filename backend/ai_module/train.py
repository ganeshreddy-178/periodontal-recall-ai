"""
train.py
Builds and trains a VGG16 transfer-learning CNN for periodontal severity
classification. Saves the model to models_saved/periodontal_cnn_model.h5.

Usage:
    python train.py --dataset /path/to/dataset --epochs 50
"""
import os
import argparse
import matplotlib.pyplot as plt
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications import VGG16
from tensorflow.keras.layers import (Dense, Dropout, Flatten,
                                      GlobalAveragePooling2D, BatchNormalization)
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import (EarlyStopping, ModelCheckpoint,
                                         ReduceLROnPlateau, TensorBoard)
from tensorflow.keras.utils import to_categorical

from data_loader  import load_dataset
from augmentation import get_train_generator, get_val_generator

CLASSES      = ["healthy", "mild", "moderate", "severe"]
NUM_CLASSES  = 4
IMG_SIZE     = 224
SAVE_DIR     = os.path.join(os.path.dirname(__file__), "models_saved")
MODEL_PATH   = os.path.join(SAVE_DIR, "periodontal_cnn_model.h5")


# -----------------------------------------------------------------------
def build_model(fine_tune_at: int = 15) -> Model:
    """VGG16 base + custom classification head."""
    base = VGG16(weights="imagenet",
                 include_top=False,
                 input_shape=(IMG_SIZE, IMG_SIZE, 3))

    # Freeze all VGG16 layers first
    for layer in base.layers:
        layer.trainable = False

    # Unfreeze the top `fine_tune_at` layers for fine-tuning
    for layer in base.layers[-fine_tune_at:]:
        layer.trainable = True

    x = base.output
    x = GlobalAveragePooling2D()(x)
    x = BatchNormalization()(x)
    x = Dense(512, activation="relu")(x)
    x = Dropout(0.5)(x)
    x = Dense(256, activation="relu")(x)
    x = Dropout(0.3)(x)
    out = Dense(NUM_CLASSES, activation="softmax")(x)

    model = Model(inputs=base.input, outputs=out)
    model.compile(
        optimizer=Adam(learning_rate=1e-4),
        loss="categorical_crossentropy",
        metrics=["accuracy"]
    )
    return model


# -----------------------------------------------------------------------
def plot_history(history, out_dir: str):
    os.makedirs(out_dir, exist_ok=True)

    # Accuracy
    plt.figure(figsize=(8, 5))
    plt.plot(history.history["accuracy"],     label="Train Accuracy")
    plt.plot(history.history["val_accuracy"], label="Val Accuracy")
    plt.title("Training vs Validation Accuracy")
    plt.xlabel("Epoch"); plt.ylabel("Accuracy")
    plt.legend(); plt.tight_layout()
    plt.savefig(os.path.join(out_dir, "accuracy_curve.png"))
    plt.close()

    # Loss
    plt.figure(figsize=(8, 5))
    plt.plot(history.history["loss"],     label="Train Loss")
    plt.plot(history.history["val_loss"], label="Val Loss")
    plt.title("Training vs Validation Loss")
    plt.xlabel("Epoch"); plt.ylabel("Loss")
    plt.legend(); plt.tight_layout()
    plt.savefig(os.path.join(out_dir, "loss_curve.png"))
    plt.close()

    print(f"Plots saved to {out_dir}")


# -----------------------------------------------------------------------
def main(args):
    os.makedirs(SAVE_DIR, exist_ok=True)

    print("Loading dataset …")
    X_train, X_val, X_test, y_train, y_val, y_test = load_dataset(args.dataset)

    train_gen = get_train_generator(X_train, y_train, batch_size=args.batch)
    val_gen   = get_val_generator(X_val,   y_val,   batch_size=args.batch)

    print("Building model …")
    model = build_model()
    model.summary()

    callbacks = [
        EarlyStopping(monitor="val_loss", patience=8, restore_best_weights=True, verbose=1),
        ModelCheckpoint(MODEL_PATH, monitor="val_accuracy", save_best_only=True, verbose=1),
        ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=4, min_lr=1e-7, verbose=1),
        TensorBoard(log_dir=os.path.join(SAVE_DIR, "logs")),
    ]

    print(f"Training for up to {args.epochs} epochs …")
    history = model.fit(
        train_gen,
        steps_per_epoch  = len(X_train) // args.batch,
        validation_data  = val_gen,
        validation_steps = len(X_val)   // args.batch,
        epochs           = args.epochs,
        callbacks        = callbacks,
    )

    plot_history(history, out_dir=SAVE_DIR)

    print("\nEvaluating on test set …")
    y_test_cat = to_categorical(y_test, num_classes=NUM_CLASSES)
    loss, acc  = model.evaluate(X_test, y_test_cat, verbose=0)
    print(f"Test Accuracy: {acc*100:.2f}%  |  Test Loss: {loss:.4f}")
    print(f"Model saved to {MODEL_PATH}")


# -----------------------------------------------------------------------
if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Train Periodontal CNN")
    parser.add_argument("--dataset", required=True, help="Path to dataset root")
    parser.add_argument("--epochs",  type=int, default=50)
    parser.add_argument("--batch",   type=int, default=32)
    main(parser.parse_args())
