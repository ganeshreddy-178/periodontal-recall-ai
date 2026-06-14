"""
evaluate.py
Evaluates a trained CNN model — confusion matrix, ROC curves, classification report.

Usage:
    python evaluate.py --model models_saved/periodontal_cnn_model.h5 --dataset /path/to/dataset
"""
import os
import argparse
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import tensorflow as tf
from sklearn.metrics import (classification_report, confusion_matrix,
                              roc_curve, auc)
from sklearn.preprocessing import label_binarize
from tensorflow.keras.utils import to_categorical

from data_loader import load_dataset

CLASSES     = ["healthy", "mild", "moderate", "severe"]
NUM_CLASSES = 4
OUT_DIR     = os.path.join(os.path.dirname(__file__), "models_saved")


def plot_confusion_matrix(cm, out_path: str):
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt="d", cmap="Blues",
                xticklabels=CLASSES, yticklabels=CLASSES)
    plt.title("Confusion Matrix")
    plt.ylabel("True Label"); plt.xlabel("Predicted Label")
    plt.tight_layout()
    plt.savefig(out_path)
    plt.close()
    print(f"Confusion matrix saved: {out_path}")


def plot_roc_curves(y_true, y_score, out_path: str):
    y_bin = label_binarize(y_true, classes=list(range(NUM_CLASSES)))
    plt.figure(figsize=(9, 7))

    for i, cls in enumerate(CLASSES):
        fpr, tpr, _ = roc_curve(y_bin[:, i], y_score[:, i])
        roc_auc     = auc(fpr, tpr)
        plt.plot(fpr, tpr, label=f"{cls} (AUC = {roc_auc:.3f})")

    plt.plot([0, 1], [0, 1], "k--")
    plt.xlabel("False Positive Rate"); plt.ylabel("True Positive Rate")
    plt.title("ROC Curves — Periodontal Severity Classification")
    plt.legend(loc="lower right"); plt.tight_layout()
    plt.savefig(out_path)
    plt.close()
    print(f"ROC curve saved: {out_path}")


def main(args):
    print("Loading model …")
    model = tf.keras.models.load_model(args.model)

    print("Loading dataset …")
    _, _, X_test, _, _, y_test = load_dataset(args.dataset)

    print("Running inference …")
    y_score = model.predict(X_test, verbose=1)
    y_pred  = np.argmax(y_score, axis=1)

    print("\nClassification Report:")
    print(classification_report(y_test, y_pred, target_names=CLASSES))

    cm = confusion_matrix(y_test, y_pred)
    plot_confusion_matrix(cm, os.path.join(OUT_DIR, "confusion_matrix.png"))
    plot_roc_curves(y_test, y_score, os.path.join(OUT_DIR, "roc_curves.png"))

    acc = np.mean(y_pred == y_test)
    print(f"\nOverall Accuracy: {acc*100:.2f}%")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Evaluate Periodontal CNN")
    parser.add_argument("--model",   required=True)
    parser.add_argument("--dataset", required=True)
    main(parser.parse_args())
