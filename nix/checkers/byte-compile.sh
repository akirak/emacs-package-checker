# Byte-compile Emacs Lisp files

# This script should be run by the builder in a nix-build task
# defined in default.nix.

# The logic is based on an implementation in makel:
# <https://gitlab.petton.fr/DamienCassou/makel/blob/master/makel.mk>

# Set PATH from buildInputs
unset PATH
for p in $buildInputs; do
    export PATH=$p/bin${PATH:+:}$PATH
done

echo "=========================================================="
echo "byte-compile on $pname"
echo "=========================================================="
emacs --version
if [[ -n "$dependencyNames" ]]; then
    echo
    echo "Added packages: $dependencyNames"
fi
echo "----------------------------------------------------------"

shopt -s extglob
cp -r $src/* .
chmod u+w -R .

echo "Running byte-compile on $files..."

result=0
for f in $files; do
    emacs --batch --no-site-file \
        --eval "(setq byte-compile-error-on-warn t)" \
        --eval "(dolist (dir $loadPaths) (add-to-list 'load-path (expand-file-name dir)))" \
        --funcall batch-byte-compile $f
    result=$((result + $?))
done

if [[ $result -eq 0 ]]; then
    echo "Byte-compilation was successful."
    # nix-build fails if you don't make the output directory
    mkdir -p $out
    echo "***** Information from nix-build"
else
    echo "Byte-compilation failed in one of $files"
fi
exit $result
