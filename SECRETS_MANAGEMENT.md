# PGP-based Secrets Management
Within this repo there are few scripts simplifying working with GPG/PGP-encrypted secrets.

The idea is simple:
> **Secrets should be stored in application code repository in GPG/PGP encrypted files. Files containing unencrypted secrets should never be checked in!
To simplify management of public/private GPG keys, we use [Keybase.io](https://keybase.io), however the process will work with any GPG key.**

Helper scripts are located in `./scripts/` directory, and include the following:
```
scripts/
├── decrypt.sh          # decrypts given "${filename}", assuming you are
|                         one of the recipients
├── encrypt.sh          # (re)encrypts given "${filename}", using keys in "${filename.recipients}"
|
├── get_keybase_keys.sh # retrieves keys from "${recipients_file}" and
|                          imports to local GPG keyring
└── list_recipients.sh  # list recipients of encrypted "${filename}"
```

> Make sure to add your unencrypted `secrets_file.txt` file (or whichever one you use to store secrets in) into `.gitignore` (`.chefignore`, `.dockerignore`, etc..)


## Prerequisites

- GPG / GNUPG cli tools and GPG-Agent
- GPG key (see [Github article describing the process](https://help.github.com/en/articles/generating-a-new-gpg-key))
- Keybase account with PGP key (optional)

On Mac, install with `brew install gnupg`


## Importing keys

In order to be able to encrypt a file containing secrets for all recipients specified in recipients file, you need to have recipient keys imported into your local GPG store.

If `secrets_file.recipients` contains Keybase-only keys, one could import them all with helper script (which is using [anapsix/keybase-keyserver-proxy](https://github.com/anapsix/keybase-keyserver-proxy)), for example:
```bash
./scripts/get_keybase_keys.sh ./examples/secrets_file.recipients
```

> alternatively, follow intended recipients on Keybase and run `keybase pgp pull`
> or import them individually with `keybase pgp pull ${keybase_username}`

You can list all GPG imported keys with `gpg --list-keys`


## Encrypting files with secrets

1. create `secrets_file.recipients` (in the same directory as `secrets_file.txt`), making sure it contains a list of intended recipients one per line in the following format: `KEYFINGERPRINT  "First Last <email@example.com>"`.

   Everything after `KEYFINGERPRINT` will be ignored and you could use it for free-form comments, but let's stick to full name and email. See [`examples/secrets_file.recipients`](./examples/secrets_file.recipients).

   **Make sure to include your own public key there, otherwise you will not be able to decrypt it yourself.**

2. import public keys from `secrets_file.recipients` to GPG-Agent with `get_keybase_keys.sh secrets_file.recipients`.

   For example:
    ```
    ./scripts/get_keybase_keys.sh ./examples/secrets_file.recipients
    ```

3. add `secrets_file.txt` to `.gitignore` (`.chefignore`, `.dockerignore`, etc..) to avoid checking in unencrypted file

4. encrypt `secrets_file.txt` with `encrypt.sh --asc secrets_file.txt`

   For example:
    ```bash
    # generates binary .gpg file
    ./scripts/encrypt.sh ./examples/secrets_file.txt

    # generates ascii armored .asc file
    ./scripts/encrypt.sh --asc ./examples/secrets_file.txt

    ```


## Decrypting files with secrets

Decrypting `secrets_file.txt` with helper script can be done with `decrypt.sh secrets_file.txt.asc`.

For example:
```bash
./scripts/decrypt.sh ./examples/secrets_file.txt.asc
```

Example of decrypting `secrets_file.txt.asc` manually:
```bash
# gpg to terminal
gpg -d ./examples/secrets_file.txt.asc

# gpg to file
gpg -d ./examples/secrets_file.txt.asc > ./examples/secrets_file.txt

# keybase to terminal
keybase pgp decrypt -i ./examples/secrets_file.txt.asc

# keybase to file
keybase pgp decrypt \
  -i ./examples/secrets_file.txt.asc \
  -o ./examples/secrets_file.txt
```


## Listing recipients

To list recipients of encrypted file, use `list_recipients.sh secrets_file.txt.asc`

For example:
```
./scripts/list_recipients.sh ./examples/secrets_file.txt.asc
```


## Adding / Removing recipients

**!! Changing secrets is essential when removing recipients !!**

Simply taking away ability to decrypt the file is not enough. Cached copies of still decryptable versions of the file might be available to removed users, in addition to Git repository history containing such versions.

1. Edit `secrets_file.recipients`, adding or removing intended recipients.

2. Re-encrypt `secrets_file.txt.asc` with helper script: `encrypt.sh --asc secrets_file.txt.asc`

   For example:
    ```bash
    ./scripts/encrypt.sh --asc ./examples/secrets_file.txt.asc
    ```
    > you must be able to decrypt the file, in order to re-encrypt it
