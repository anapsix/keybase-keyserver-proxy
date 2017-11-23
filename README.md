# keybase-keyserver-proxy

Annoyed about not being able to do import public keys from Keybase with gpg `--recv-keys`?
Run yourself a proxy..

## Step 1 - optional - Build
```
docker build -t keybase-keyserver-proxy .
```

## Step 2 - Run
```
docker run -d --name kkp -p 11371:11371 anapsix/keybase-keyserver-proxy
```

## Step 3 - Profit!
```
gpg --keyserver 127.0.0.1 --recv-keys B416D3911B1D1AA0D47D5F4E5E93F7F309CAC1B2
```

## Step 4 - cleanup
```
docker rm -f kkb
```