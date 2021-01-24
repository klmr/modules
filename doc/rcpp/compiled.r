# Load compiled module meta information, and load R wrapper code, which, in
# turn, loads the compiled module via `dyn.load`.
load_dynamic = function (prefix) {
    context = readRDS(module_file(sprintf('%s.rds', prefix)))
    source(context$rSourceFilename, local = parent.frame())
}

load_dynamic('convolve')
