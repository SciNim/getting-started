import nimib, nimibook

nbInit(theme=useNimibook)

nbText: md"""
# 🤖👩‍🎓 Machine Learning

In this tutorial we will cover the basics of [Machine Learning]
in Nim by showing examples of the three classical tasks of
[Clustering], [Classification], and [Regression]. 

As reference dataset we will use [penguins dataset].
An exploration of this dataset in Nim is available as an [example notebook] of nimib.
Using this dataset we will:
  - cluster penguins' features and see how much this matches species using [k-means clustering]
  - classify penguins' sex and species starting from various sets of features using [logistic regression]
  - predict the weight of penguins based on their bill size using [linear regression]

Machine learning main concern is to build algorithms for automated data-driven prediction.
The measure of success of such a modelling activity is usually encapsulated in some performance metric
computed on specific subsets of data called [training, validation and test].
In our examples we will:
  - split the dataset in training and test
  - process features appropriately
  - fit the model on training set
  - predict the test set using the trained model
  - compute various metrics on predictions, appropriate for each of the above tasks
  - validate our modelling approaches through [cross-validation]

We will be using [arraymancer] for the implementation of machine learning algorithms,
[datamancer] for manipulating data, [ggplotnim] for visualization.
In Nim there is not (yet) a specific library that encapsulate
machine learning concepts such as the `Estimator` of [scikit-learn].
In this tutorial we will also try to build a simple api
that could be a seed for a future [scinim/learn] library.

[Machine Learning]: https://en.wikipedia.org/wiki/Machine_learning
[Clustering]: https://en.wikipedia.org/wiki/Cluster_analysis
[Classification]: https://en.wikipedia.org/wiki/Statistical_classification
[Regression]: https://en.wikipedia.org/wiki/Regression_analysis
[penguins dataset]: https://allisonhorst.github.io/palmerpenguins/
[example notebook]: https://pietroppeter.github.io/nimib/penguins.html
[logistic regression]: https://en.wikipedia.org/wiki/Logistic_regression
[k-means clustering]: https://en.wikipedia.org/wiki/K-means_clustering
[linear regression]: https://en.wikipedia.org/wiki/Linear_regression
[training, validation and test]: https://en.wikipedia.org/wiki/Training,_validation,_and_test_sets
[cross-validation]: https://en.wikipedia.org/wiki/Cross-validation_(statistics)
[arraymancer]: https://github.com/mratsim/Arraymancer
[datamancer]: https://github.com/scinim/datamancer
[ggplotnim]: https://github.com/vindaar/ggplotnim
[scikit-learn]: https://scikit-learn.org/stable/
[scinim/learn]: https://github.com/scinim/learn
"""

nbSave