#' Distance Calculation
#'
#' Small intermediate function for euclidean distance calculation between 
#' MCA feture coordinates and cell coordinates.
#'
#' @param X Seurat or SingleCell Experiment Object
#' @param reduction Which dimensionality reduction to use, must be based on MCA.
#' @param dims A vector of integers indicating which dimensions to use with 
#' reduction embeddings and loadings for distance calculation.
#' @param features Character vector of feature names to subset 
#' feature coordinates. If not specified will take all features available from specified reduction Loadings.
#' @param cells Character vector of cell names to subset cell coordinates. 
#' If not specified will take all cells available from specified reduction Embeddings.
#'
#' @return Distance Matrix with genes at row and cellls at column
GetCellGeneDistance <-
    function(X, reduction, dims, features, cells) {
        UseMethod("GetCellGeneDistance", X)
    }

#' @rdname GetCellGeneDistance
#' @export
GetCellGeneDistance.Seurat <-
    function(X, reduction = "mca", dims, features = NULL, cells = NULL) {
        check <-
            checkCellIDArg(
                X = X,
                reduction = reduction,
                dims = dims,
                features = features,
                cells = cells
            )
        dims <- check$dims
        features <- check$features
        cells <- check$cells
        message("\ncalculating distance\n")
        cellsEmb <- Embeddings(X, reduction)[cells, dims]
        genesEmb <- Loadings(X, reduction)[features, dims]
        CellGeneDistance <- pairDist(cellsEmb, genesEmb)
        return(CellGeneDistance)
    }

#' @rdname GetCellGeneDistance
#' @export
GetCellGeneDistance.SingleCellExperiment <-
    function(X, reduction = "MCA", dims, features = NULL, cells = NULL) {
        check <-
            checkCellIDArg(X = X, reduction = reduction, dims = dims, features = features, cells = cells)
        dims <- check$dims
        features <- check$features
        cells <- check$cells
        message("\ncalculating distance\n")
        cellsEmb <- reducedDim(X, reduction)[cells, dims]
        genesEmb <-
            attr(reducedDim(X, reduction), "genesCoordinates")[features, dims]
        CellGeneDistance <- pairDist(cellsEmb, genesEmb)
        return(CellGeneDistance)
    }

#' Ranking Extraction
#'
#' Intermediate function for ranking extraction feom Cell Gene Distance Matrix
#'
#' @param X Seurat or SingleCell Experiment Object
#' @param reduction Which dimensionality reduction to use, must be based on MCA.
#' @param dims A vector of integers indicating which dimensions to use with reduction embeddings and loadings for distance calculation.
#' @param features Character vector of feature names to subset feature coordinates. If not specified will take all features available from specified reduction Loadings
#' @param cells Character vector of cell names to subset cell coordinates. If not specified will take all features available from specified reduction Embeddigns.
#'
#' @return A cell named list of gene rankings ordererd by distances from shortest (most specfic) to farthest (less specific)
#' @export
#'
#' @examples
#' \dontrun{
#' seuratPbmc <- RunMCA(seuratPbmc, nmcs = 5)
#' }
GetCellGeneRanking <-
    function(X, reduction, dims, features, cells) {
        UseMethod("GetCellGeneRanking", X)
    }

#' @rdname GetCellGeneRanking
#' @export
GetCellGeneRanking.Seurat <-
    function(X, reduction = "mca", dims = seq(50), features = NULL, cells = NULL) {
        CellGeneDistance <-
            GetCellGeneDistance(X = X, dims = dims, reduction = reduction, features = features, cells = cells
            )
        CellGeneRanking <- DistSort(CellGeneDistance)
        return(CellGeneRanking)
    }

#' @rdname GetCellGeneRanking
#' @export
GetCellGeneRanking.SingleCellExperiment <-
    function(X, reduction = "MCA", dims = seq(50), features = NULL, cells = NULL) {
        CellGeneDistance <-
            GetCellGeneDistance(X = X, dims = dims, reduction = reduction, features = features, cells = cells
            )
        CellGeneRanking <- DistSort(CellGeneDistance)
        return(CellGeneRanking)
    }

#' Gene sets extraction from MCA
#'
#' Calculate cells and genes distances, rank them per cell and extract top n features
#'
#' @param X Seurat or SingleCell Experiment Object
#' @param reduction Which dimensionality reduction to use, must be based on MCA.
#' @param dims A vector of integers indicating which dimensions to use with reduction embeddings and loadings for distance calculation.
#' @param features Character vector of feature names to subset feature coordinates. If not specified will take all features available from specified reduction Loadings
#' @param cells Character vector of cell names to subset cell coordinates. If not specified will take all features available from specified reduction Embeddigns.
#' @param n.features single integer specifying how many top features should be extracted from the ranking
#'
#' @return A cell named list of gene rankings ordererd by distances from shortest (most specfic) to farthest (less specific)
#' @export
#' @importFrom pbapply pblapply
#' @examples
#' seuratPbmc <- RunMCA(seuratPbmc, nmcs = 5)
#' GroupGeneRanking <- GetGroupGeneRanking(seuratPbmc, group.by = "seurat_clusters", dims = 1:5) 

GetCellGeneSet <-
    function(X, reduction = "mca", dims, features, cells, n.features) {
        UseMethod("GetCellGeneSet", X)
    }

#' @rdname GetCellGeneSet
#' @export
GetCellGeneSet.Seurat <-
    function(X, reduction = "mca", dims = seq(50), features = NULL, cells = NULL, n.features = 200) {
        CellGeneRanking <-
            GetCellGeneRanking(X, dims, reduction = reduction, features = features, cells = cells)
        message("\ncreating geneset\n")
        geneset <-
            pblapply(CellGeneRanking, function(x)
                names(head(x, n.features)))
        return(geneset)
    }

#' @rdname GetCellGeneSet
#' @export
GetCellGeneSet.SingleCellExperiment <-
    function(X, reduction = "MCA", dims = seq(50), features = NULL, cells = NULL, n.features = 200) {
        CellGeneRanking <-
            GetCellGeneRanking(X, dims, reduction = reduction, features = features, cells = cells)
        message("\ncreating geneset\n")
        geneset <-
            pblapply(CellGeneRanking, function(x)
                names(head(x, n.features)))
        return(geneset)
    }

#' Distance Calculation with rdist
#'
#' Small modification of rdist from fields package to include column and rownames
#'
#' @param x a matrix
#' @param y a matrix
#'
#' @return A Distance Matrix
pairDist <- function(x, y) {
        z <- fastPDist(y, x)
        rownames(z) <- rownames(y)
        colnames(z) <- rownames(x)
    return(z)
}