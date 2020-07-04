#!/bin/sh
# Parse languages and ensure that "en" is built last
cd source || exit 1
LANGUAGES="$(python -c 'import conf; print(" ".join(sorted((lang for lang in conf.supported_languages.keys() if lang != "en"), reverse=True)))')"
cd .. || exit 1
LANGUAGES="$LANGUAGES en"
NUM_LANGUAGES="$(printf '%s' "$LANGUAGES" | wc -w)"

# Write _redirects file
mkdir -p build/html
printf '/           /latest/               302\n' > build/html/_redirects
printf '/latest/*   /2.2/:splat            301\n' >> build/html/_redirects

i=1
for lang in $LANGUAGES
do
    printf -- '----- Building language "%s"... [%d/%d] -----\n' "$lang" "$i" "$NUM_LANGUAGES"

    if [ "$lang" = "en" ]
    then
        printf '/:version/* /:version/en/:splat    301\n' >> build/html/_redirects
    else
        printf '/:version/* /:version/%s/:splat    301 Language=%s\n' "$lang" "$lang" >> build/html/_redirects
    fi
    make versionedhtml SPHINXOPTS="-Q -j $(nproc) -Dlanguage=$lang"
    make versionedlatexpdf SPHINXOPTS="-Q -j $(nproc) -Dlanguage=$lang" >/dev/null
    i=$((i + 1))
done

cd build/latex || exit 1
for file in */*/Mixxx-Manual.pdf
do
    cp "$file" "../html/$file"
done