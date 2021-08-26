# keybase-keyserver-proxy

[![Docker Pulls](https://img.shields.io/docker/pulls/anapsix/keybase-keyserver-proxy)](https://hub.docker.com/r/anapsix/keybase-keyserver-proxy)

Annoyed about not being able to do import public keys from Keybase with gpg `--recv-keys`?
Run yourself a proxy..

> See [SECRETS_MANAGEMENT.md][1] for usage examples, and musings on keeping sensitive files in SCM repos.

## Step 1 - optional - Build
```bash
docker build -t keybase-keyserver-proxy .
```

## Step 2 - Run
```bash
# start freshly built image
docker run -d --name kkp -p 11371:11371 keybase-keyserver-proxy

# or use one from Docker Hub
docker run -d --name kkp -p 11371:11371 anapsix/keybase-keyserver-proxy
```

## Step 3 - Profit!
```bash
gpg --keyserver localhost --recv-keys B416D3911B1D1AA0D47D5F4E5E93F7F309CAC1B2
```

## Step 4 - cleanup
```bash
docker rm -f kkp
```

[link reference]::
[1]: https://github.com/anapsix/keybase-keyserver-proxy/blob/master/SECRETS_MANAGEMENT.md
