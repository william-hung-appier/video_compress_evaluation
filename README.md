# PoC for checking compressed result comparing to the original files

> Conclusion: currently we can define those VMAF mean score is lower than 60 is a "bad" compressed file

## Start with docker (recommend)

> We have a utility [Makefile for dev](./Makefile.dev) to help run up [Dockerfile](./Dockerfile) image

- Run up docker image and exec inside, we uses mount volume so that you can edit the files on your local and the docker files will also be synced

```bash
# Build docker
make -f Makefile.dev docker-build

# Run docker
make -f Makefile.dev docker-up

# Exec inside docker
make -f Makefile.dev docker-exec
```

- Run the [Makefile](./Makefile) command for your specific purpose, for example:

```bash
make get-all-scores THREADS_COUNT=2
```

## Start with local (macOS)

1. Build vmaf via: <https://github.com/Netflix/vmaf/blob/master/libvmaf/README.md>
2. download ffmpeg with vmaf enable

```bash
brew tap homebrew-ffmpeg/ffmpeg && brew install homebrew-ffmpeg/ffmpeg/ffmpeg --with-libvmaf
```

3. Run with Makefile command to get your desired video score, for example:

```bash
make get-all-scores THREADS_COUNT=8
```
