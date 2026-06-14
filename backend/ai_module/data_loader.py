"""
data_loader.py
Loads and prepares the periodontal image dataset for training.

Expected directory layout:
  dataset/
    train/
      healthy/
      mild/
      moderate/
      severe/
    val/
      ...
    test/
      ...
"""
import os
import cv2
import numpy as np
from sklearn.model_selection import train_test_split

CLASSES      = ["healthy", "mild", "moderate", "severe"]
IMG_SIZE     = 224
CLASS_TO_IDX = {c: i for i, c in enumerate(CLASSES)}


def preprocess(img_bgr: np.ndarray) -> np.ndarray:
    """Resize + CLAHE + denoise + normalize."""
    img = cv2.resize(img_bgr, (IMG_SIZE, IMG_SIZE))
    lab = cv2.cvtColor(img, cv2.COLOR_BGR2LAB)
    l, a, b = cv2.split(lab)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    l     = clahe.apply(l)
    img   = cv2.cvtColor(cv2.merge([l, a, b]), cv2.COLOR_LAB2BGR)
    img   = cv2.fastNlMeansDenoisingColored(img, None, 10, 10, 7, 21)
    return img.astype(np.float32) / 255.0


def load_dataset(dataset_root: str):
    """
    Scans all split dirs (train/val/test) and returns:
        X_train, X_val, X_test, y_train, y_val, y_test
    as numpy arrays.
    """
    data, labels = [], []

    for split in ["train", "val", "test"]:
        split_dir = os.path.join(dataset_root, split)
        if not os.path.isdir(split_dir):
            continue
        for cls in CLASSES:
            cls_dir = os.path.join(split_dir, cls)
            if not os.path.isdir(cls_dir):
                continue
            for fname in os.listdir(cls_dir):
                if not fname.lower().endswith((".jpg", ".jpeg", ".png")):
                    continue
                path = os.path.join(cls_dir, fname)
                img  = cv2.imread(path)
                if img is None:
                    continue
                data.append(preprocess(img))
                labels.append(CLASS_TO_IDX[cls])

    X = np.array(data,   dtype=np.float32)
    y = np.array(labels, dtype=np.int32)

    # If only a single pool, split here
    if X.shape[0] == 0:
        raise RuntimeError("No images found. Check dataset_root path.")

    X_train, X_tmp, y_train, y_tmp = train_test_split(
        X, y, test_size=0.30, random_state=42, stratify=y)
    X_val, X_test, y_val, y_test = train_test_split(
        X_tmp, y_tmp, test_size=0.50, random_state=42, stratify=y_tmp)

    print(f"Dataset — train:{len(X_train)} val:{len(X_val)} test:{len(X_test)}")
    return X_train, X_val, X_test, y_train, y_val, y_test
