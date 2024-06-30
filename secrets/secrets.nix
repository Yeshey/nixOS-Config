let
  # Usually the public key of your user can be found in ~/.ssh/id_rsa.pub and the system one in /etc/ssh/ssh_host_rsa_key.pub
  # If you change the public keys in secrets.nix, you should rekey your secrets:
  # agenix --rekey
  # agenix -e <filename>.age # to create new secrets

  # User key
  # ~/.ssh/my_identity.pub
  yeshey_my_identity = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDgOfJysYZT/VOwxg/FWCYDnjrSEilzK+YO1JVF5mfkS+eGLWc7IqISNZzPOlNLccIx4vXYr6bAM3wtLAOHajLs4TbnfUe9zfRVO0cGF93eLyOD3VUMVkljgQ4mrt+p2COutvX5j31/JZjAHrp4r/RJiCsWGXib1DGGY52L4g1Ty6pnqY7wErtb56TaHpla/u1BJqHVTTJDg/oZI9BgMObMSRi77QIHZPehmjE04zYz/m2C9fgQuTpHKWU2Ec7zyKp5EuMPWtXbVE0qlZ0J/yiqexu4mT3GRNEIQvo810a1G0uDORxBxP37f3l2PBI0faZk7gCE6baEuh0ejfXhA79TzriWa0yBdevL9pVbMMt9bbolX/CP9lhQX6oaBtWPr2EoXVR1ZyRonya8rqylpYjsPUtAuM35nQSALgsdkXhzuZV2Nw1LLZn0sqaYANmMBKLtDDm3+cOEiXIdFndFI045DvcbfVhdvJeMjrUXGcgFXp+NyAAMa9yY8uMpFKk1qws2eWvEJV1A4gIBJS/bARdcYDwNvH62ASRGNfSkxfWnibLagJgec+a1aUTuEWSqvLJA7lduNC+BZTsWz71h9oBMX6oTqYgyUl1dPOB/+OiVmwfW1tRcAHhxTInEeq7q/GreUUoLk8M33JjwLBF0t4NXj+YqK/zHx+VSZDKoz6ce4w== yeshey@Manjaro-Laptop";

  users = [ yeshey_my_identity ];

  # Host key
  # /etc/ssh/ssh_host_rsa_key.pub
  hyrulecastle = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCpi5nzHpzQmwWZ+lVcJnrlTpKKqyNSS924TtqGeUSquXo87NFzXzy1vOqDFWK8x5FWMDWI8G+M0yY3UvBGYTuqG+O+cgozxfcDyDw51afGpfSRBwWoTyZKROFCebkERMms59snFFybyUh8hDFAzMHxiKoyqqaXuJ9yPLDNw+XIaqBO8CjT90+U7MqT1SPVjgwmLO+SD+SC43xZf+Y7iGgRIovkgqcddoHCaSS3XrtNRyv5/7F1J50XA8/3Qq57vpoRT4e8tEQaCm9GpQfQCECfckms3ipQnB3QQ/yheX78xpy0MMFvtySYhgkC9W9o2RRj2U9pDm8HsxOSyjoKrP3v80UF3Zf3SN9w3YmCb9JWOrbeM/mHsvNy7sQ1DG9iOFFbsp0phPPrufxoPejGBhXEOWVFUeq3OY0Yq6VfnRgDi1Ab15L+50NHh/Kw5vpYbZSgwPl4u1iE33x+lYMFnmokWndgyPBSkROSAKsMYhWoNbXWq4aWhRomVP3EMhyv+vgWqr2M9KYbfQHN0DMmFCAELx05QuIGb7nvX0OGT503Lfei+Q7uglEWv8L/C5z99uO/n19oYOC/ORoZFBIbFmGa2uyqhQamiViItu6J3+arx5PXAuENArDuT/MvBvwP6pd5kKnwqPMfNhUQNsoqTIeeirgM8pdBU9Moimkxzzpl2Q== root@nixos";
  kakariko = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC0JpFbPE81pm7ptuiGgBddA3QyEb6WaCqJuD5gtAFCawKczjfNVA0Mwd0qQqOcelvRJfaEafFTe9DotzcAAxcLOHUDat3unan14I2ylpbWVVfhQz1X5CpXdsK+/p2KJjjhcAbNxS38YB0r7HDudqpmZlLFoN/+sxJJd5+3tcEvkBwBB4TVpjSwixN9Y1Y8JMS65tWP4vJ0V+SHC9gyhecvd8o7fOK1/H+BZ+oi3Ab7DLAYr7/JuRoUz5iy7hpb6QNPolIOjGfmNqRZHJrVmzwVSHXy172BL0Ytir7VLrHzWPe9DLIZNce5Wan4L2/vJYeUyfg12PMH+ew6ITRCRBzFhnRy6A1TC+kAyZ18clp/SbhRvBJ+F9hgt8EbQ4c4cx8RcmSTBn/IMiQ1ETS6fad3BC8UpbumTeRv4q6FFX7bQlsgjKhTlTtytk7tJIKncXKkR4AOfIgEdG1ZkeGZmYWq4HO5zDHFLdB5blyoPh6lvNEAOe6LyOurIRBsx0qP8byNGswBdzaY8t83gXF0q+hnmDcJXmfnPF6P2XSyihtMFYYmLVCbAA8fEXktUGyz0gfHDB5FKTEkctIqkhBSooyxJ4PFxt6Pxanhxn8d/CPipbtGIoghDpzMiBiuIeWgfuQ6Z6NOn8unQEh0+R6Mj9yu1WzDP/fSLhz2KOBEJHDmlw== root@nixos";
  skyloft = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCcxnXRmBcFrMY90gEJJvqtYqaQH7NLxXS6ndGzlciim78j+uEdk61gH+gRveHZMHIbycIHXvHGPEMKVHy3oIuudctmn88J36QHE1Y8bH8FrjDyBiCEgyOTnz3pRmS+YvsMJyPtC1UJBqnj0/MzorvS+HrFXCfNfWFDYSEj6/w0yHosqjsIhXjvQ/JIgaJvt+67xJlvsbYbbdtjijk+EmtxHtBB3ofKK2B0kUBbwYulbPzYKiZ/0sP/WtF5nm6DXt5DPpPYd4GAFx2lOVok38ZZuc2DyLM+lxMfMOTZied3RgTagly+VkhQtIHh+FNH5mY3JQnLRDxORa/+3BOFeaufCkewT8xRc8ZBbFMJJswRTiwVSwSr+2Phi+qy/+dUKuWrB2PLWgbqatwKc0RJ56EoPWOgIEqBFS30reO5N4BaNxiQGFpKqezkQ7vzDKpuI2FpLIruA+OAWZkHKBl0ZLs2jJ45SkkkvgACq4iCdjLBFYOUQ+GxNS/eaf4l/SvGF0ImzJnt2TlY6co69XuHlnqx9iebl9DXqh6ArYOZX1ZbarjaHCd2efeL0B6FThT50xyis8mSVrMchrfogf2oKr1JECaYcbLpujGt4FOXp/v45+W1ZIvIeR7UC2NA5J0na2LGmH3fXnuNcOmJg8Uu2V1dbH+ZL4XJZXznmnsVI0Eozw== root@nixOS-OracleArm";
  # mordor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGdT6E0OwCh/fF1ji0ExyH+4zhh1znuoT+sCeDgYn9N1";

  systems = [ hyrulecastle kakariko skyloft ];

  # Backup keys
  # backup = "";
in
{
  # You need at least one to decrypt. These are the users and systems that will be able to decrypt the .age files later with their corresponding private keys.
  "my_identity.age".publicKeys = systems ++ users; # [hyrulecastle2];
  "onedriver_auth.age".publicKeys = systems ++ users;
  "free_games.age".publicKeys = systems ++ users;
}
