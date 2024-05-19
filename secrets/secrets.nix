let
  # User key
  # ~/.ssh/my_identity.pub
  yeshey_my_identity = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDgOfJysYZT/VOwxg/FWCYDnjrSEilzK+YO1JVF5mfkS+eGLWc7IqISNZzPOlNLccIx4vXYr6bAM3wtLAOHajLs4TbnfUe9zfRVO0cGF93eLyOD3VUMVkljgQ4mrt+p2COutvX5j31/JZjAHrp4r/RJiCsWGXib1DGGY52L4g1Ty6pnqY7wErtb56TaHpla/u1BJqHVTTJDg/oZI9BgMObMSRi77QIHZPehmjE04zYz/m2C9fgQuTpHKWU2Ec7zyKp5EuMPWtXbVE0qlZ0J/yiqexu4mT3GRNEIQvo810a1G0uDORxBxP37f3l2PBI0faZk7gCE6baEuh0ejfXhA79TzriWa0yBdevL9pVbMMt9bbolX/CP9lhQX6oaBtWPr2EoXVR1ZyRonya8rqylpYjsPUtAuM35nQSALgsdkXhzuZV2Nw1LLZn0sqaYANmMBKLtDDm3+cOEiXIdFndFI045DvcbfVhdvJeMjrUXGcgFXp+NyAAMa9yY8uMpFKk1qws2eWvEJV1A4gIBJS/bARdcYDwNvH62ASRGNfSkxfWnibLagJgec+a1aUTuEWSqvLJA7lduNC+BZTsWz71h9oBMX6oTqYgyUl1dPOB/+OiVmwfW1tRcAHhxTInEeq7q/GreUUoLk8M33JjwLBF0t4NXj+YqK/zHx+VSZDKoz6ce4w== yeshey@Manjaro-Laptop";

  # Host key
  # /etc/ssh/ssh_host_rsa_key.pub
  hyrulecastle = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCpi5nzHpzQmwWZ+lVcJnrlTpKKqyNSS924TtqGeUSquXo87NFzXzy1vOqDFWK8x5FWMDWI8G+M0yY3UvBGYTuqG+O+cgozxfcDyDw51afGpfSRBwWoTyZKROFCebkERMms59snFFybyUh8hDFAzMHxiKoyqqaXuJ9yPLDNw+XIaqBO8CjT90+U7MqT1SPVjgwmLO+SD+SC43xZf+Y7iGgRIovkgqcddoHCaSS3XrtNRyv5/7F1J50XA8/3Qq57vpoRT4e8tEQaCm9GpQfQCECfckms3ipQnB3QQ/yheX78xpy0MMFvtySYhgkC9W9o2RRj2U9pDm8HsxOSyjoKrP3v80UF3Zf3SN9w3YmCb9JWOrbeM/mHsvNy7sQ1DG9iOFFbsp0phPPrufxoPejGBhXEOWVFUeq3OY0Yq6VfnRgDi1Ab15L+50NHh/Kw5vpYbZSgwPl4u1iE33x+lYMFnmokWndgyPBSkROSAKsMYhWoNbXWq4aWhRomVP3EMhyv+vgWqr2M9KYbfQHN0DMmFCAELx05QuIGb7nvX0OGT503Lfei+Q7uglEWv8L/C5z99uO/n19oYOC/ORoZFBIbFmGa2uyqhQamiViItu6J3+arx5PXAuENArDuT/MvBvwP6pd5kKnwqPMfNhUQNsoqTIeeirgM8pdBU9Moimkxzzpl2Q== root@nixos";
  # mordor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGdT6E0OwCh/fF1ji0ExyH+4zhh1znuoT+sCeDgYn9N1";

  # Backup keys
  # backup = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCY/Ca8AoMeANMhFxdGXILorO/hnrtDkVofgyLHbprPZ6CED593fIrWTPreLvuCCukPQlB+VFkxvhVHwHgSX2cWzSlPq8n6ERwSneEQ0Yknxw1m4iLYQfktEyjJgR0kR+r6A9Mi6ocVnQFKmd7MLBtVdrmbakIBAHQnSz3w14k2OkCnPo3QfwcZg57ZiZF/JPYqcsWndmVFm4qcl1hQn1Fm5BRg+saB5gYD1abnRYrlfYS2Ti7whN4j6EorXNgGsz3peSoeqyILz/ilv6c0/FvFHHSwTTSiDDoF1unxruSLTuRL9sshlGasmWbLJzJBRYKsgdBEIZAVnEe9+v5ZaO0gTMVawkEIVt4oY9SYCa4cOysm/XXJdKhUn7WgSNbFbRv4O+5kSIVB02CcuiNJ0/ahqQ3jIXynr6MOAJeDxgz/KtKmIw70BzdzRZVK9cC3a9m2+vetw1fLi5ypf6NgapYdMxyuMwBED4M0BJfN6Pbcz1Ut9QjCaKmexRbZKkG0SSrxAbfsWzGfUuSyFPVuwbBm4Jaw+zRn7DMC7gbNpj36q/GKoqMb1uqp49mwNDLdh8FP/NTRSZuJUhsjKVuj5pDQBXUNwRE8w5vI8MISIO8Jv76hVGk8NtBLLGhx3N8nXVWzwzUaXY9hMOqcIhAUoX/XKX59rboXDOWPsFX4ppxqbQ==";
in
{
  # These are the users and systems that will be able to decrypt the .age files later with their corresponding private keys. You can obtain the public keys from
  # "nasgul_wireguard_priv_key.age".publicKeys = [ nasgul mordor_user ];

  /*
  # Tokens
  "extra_access_tokens.age".publicKeys = [ nasgul mordor mordor_user ];

  # Nasgul
  "nasgul_wireguard_priv_key.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_mullvad_priv_key.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_cache_priv_key.pem.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_authelia_jwt_secret.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_authelia_storage_encryption_key.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_authelia_hmac_secret.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_authelia_issuer_private_key.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_authelia_mysql_password.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_authelia_config.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_nextcloud_admin_password.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_authelia_session_secret.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_ldap_password.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_minio_root_credentials.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_sendgrid_token.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_gitea_actions_token.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_restic_s3_key.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_restic_password.age".publicKeys = [ nasgul mordor_user backup ];
  "nasgul_lldap_private_key.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_lldap_jwt_secret.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_lldap_user_pass.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_miniflux_admin_credentials.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_miniflux_client_id.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_miniflux_client_secret.age".publicKeys = [ nasgul mordor_user ];
  "nasgul_minio_credentials.age".publicKeys = [ nasgul mordor_user ];
  "cloudflare_token.age".publicKeys = [ nasgul mordor_user ];
  "cloudflare_email.age".publicKeys = [ nasgul mordor_user ];

  # Mordor
  "mordor_cache_priv_key.pem.age".publicKeys = [ mordor mordor_user ];
  "mordor_mullvad_priv_key.age".publicKeys = [ mordor mordor_user ];
  */
}
