import numpy as np
import matplotlib as mpl
mpl.use('Agg')
import matplotlib.pyplot as plt
import csv

from scipy.stats import randint as sp_randint
from sklearn import datasets
from sklearn import preprocessing
from sklearn.cross_validation import train_test_split, KFold
from sklearn.metrics import accuracy_score, confusion_matrix
from sklearn.feature_selection import VarianceThreshold, SelectKBest, f_classif, chi2
from sklearn.pipeline import Pipeline
from sklearn import metrics
from sklearn.ensemble import VotingClassifier, RandomForestClassifier
from sklearn.svm import NuSVC, SVC, LinearSVC
from sklearn.calibration import CalibratedClassifierCV
from sklearn.multiclass import OneVsRestClassifier
from sklearn.grid_search import RandomizedSearchCV, GridSearchCV
from scipy.stats import randint as sp_randint
from numpy.random import uniform as uniform
from sklearn import tree
from sklearn.decomposition import PCA, FastICA


row_data = []
row_target = []
normalize = False
total_sum = 0

with open('./ppv_data_learning.csv','rb') as csvfile:
    spamreader = csv.reader(csvfile, delimiter=' ', quotechar='|')
    row_num = 1
    for row in spamreader:
        if row_num >= 100:
            temp_row = list(map(float,row[0].split(',')))
            row_data.append(temp_row[0:-1])
            row_target.append(temp_row[-1])
        row_num = row_num + 1

kf = KFold(len(row_data), n_folds=20, shuffle=False)

row_data = np.array(row_data)
row_target = np.array(row_target)

for train_index, test_index in kf:
    rowf_train, rowf_test = row_data[train_index], row_data[test_index]
    rowt_train, rowt_test = row_target[train_index], row_target[test_index]
    
    rfc = RandomForestClassifier() 
    
    param_grid = {
    'max_depth': [None,2,3,4,5],
    'min_samples_split': np.random.random_integers(1,45,50),
    'min_samples_leaf': np.random.random_integers(1,20,25),
    'n_estimators': np.random.random_integers(200,701,1000),
    'max_features': ['auto', 'sqrt', 'log2'],
    'class_weight': [None,"balanced"],
    'oob_score': [True,False],
    'criterion': ["gini", "entropy"],
    'bootstrap': [True,False]
    }
    
    CV_rfc = RandomizedSearchCV(estimator=rfc, param_distributions=param_grid, n_iter=10, cv= 10)
    
    pipeline = Pipeline([('std_scale', preprocessing.StandardScaler()), ('1', CV_rfc)])
   
    pipeline.fit(rowf_train, rowt_train)
    eclf1_predict = pipeline.predict(rowf_test)
    accuracy = accuracy_score(rowt_test, eclf1_predict)
    total_sum += accuracy
    print accuracy
    print CV_rfc.best_estimator_
print total_sum/20