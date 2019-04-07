import os
import pandas as pd
import numpy as np
import torch
import matplotlib.pyplot as plt
from torch.utils.data import Dataset, DataLoader

def show_adjmat(adjmat, idx=None):
    "Show adjacency matrix"
    if idx is not None:
        plt.imshow(adjmat[:,idx][idx])
    else:
        plt.imshow(adjmat)
    plt.pause(.001)

def vec_to_mat(adj_vec):
    n = int((1+np.sqrt(1+8*len(adj_vec)))/2)
    adj_mat = np.zeros((n,n), dtype=float)
    low_tri_idx = np.tril_indices(n,-1)
    adj_mat[low_tri_idx] = adj_vec
    adj_mat = adj_mat + adj_mat.T
    np.fill_diagonal(adj_mat, 1.)
    return adj_mat

class AdjMatDataset(Dataset):

    def __init__(self, mats_dir, rsn_csv, transform=None):
        """
        Initialize the class with the path of folder saving
        all csv filed adjacency matries
        """
        self.mats_dir = mats_dir
        self.mats_arr = os.listdir(mats_dir)
        rsn = pd.read_csv(rsn_csv)
        self.rsn7 = rsn['rsn7'].values
        self.rsn17 = rsn['rsn17'].values
        self.cenX = rsn['cenX'].values
        self.cenY = rsn['cenY'].values
        self.cenZ = rsn['cenZ'].values
        self.transform = transform
        self.low_tri_idx = np.tril_indices(rsn.shape[0],-1)

    def __len__(self):
        return len(os.listdir(self.mats_dir))
    
    def __getitem__(self, idx):
        mat_name = self.mats_arr[idx]
        file_name = os.path.join(self.mats_dir, mat_name)
        adj_mat = torch.tensor(pd.read_csv(file_name, header=None).values, dtype=torch.float)
        sess_list = mat_name[:-4].split('_')
        sample = {'adj_mat': adj_mat,
                  'adj_vec': adj_mat[self.low_tri_idx], 
                  'subj': sess_list[0],
                  'scan_type': sess_list[1],
                  'task': sess_list[2],
                  'phase': sess_list[3],
                  'name': mat_name[:-4]}
        if self.transform:
            sample = self.transform(sample)
        
        return sample