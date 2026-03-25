let
  # Usually the public key of your user can be found in ~/.ssh/id_rsa.pub and the system one in /etc/ssh/ssh_host_rsa_key.pub
  # If you change the public keys in secrets.nix, you should rekey your secrets:
  # agenix --rekey -i ~/.ssh/my_identity
  # agenix -e <filename>.age -i ~/.ssh/my_identity # to create new secrets

  # User key
  # ~/.ssh/my_identity.pub
  yeshey_my_identity = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDgOfJysYZT/VOwxg/FWCYDnjrSEilzK+YO1JVF5mfkS+eGLWc7IqISNZzPOlNLccIx4vXYr6bAM3wtLAOHajLs4TbnfUe9zfRVO0cGF93eLyOD3VUMVkljgQ4mrt+p2COutvX5j31/JZjAHrp4r/RJiCsWGXib1DGGY52L4g1Ty6pnqY7wErtb56TaHpla/u1BJqHVTTJDg/oZI9BgMObMSRi77QIHZPehmjE04zYz/m2C9fgQuTpHKWU2Ec7zyKp5EuMPWtXbVE0qlZ0J/yiqexu4mT3GRNEIQvo810a1G0uDORxBxP37f3l2PBI0faZk7gCE6baEuh0ejfXhA79TzriWa0yBdevL9pVbMMt9bbolX/CP9lhQX6oaBtWPr2EoXVR1ZyRonya8rqylpYjsPUtAuM35nQSALgsdkXhzuZV2Nw1LLZn0sqaYANmMBKLtDDm3+cOEiXIdFndFI045DvcbfVhdvJeMjrUXGcgFXp+NyAAMa9yY8uMpFKk1qws2eWvEJV1A4gIBJS/bARdcYDwNvH62ASRGNfree_gamesfSkxfWnibLagJgec+a1aUTuEWSqvLJA7lduNC+BZTsWz71h9oBMX6oTqYgyUl1dPOB/+OiVmwfW1tRcAHhxTInEeq7q/GreUUoLk8M33JjwLBF0t4NXj+YqK/zHx+VSZDKoz6ce4w== yeshey@Manjaro-Laptop";

  users = [ yeshey_my_identity ];

  # Host key
  # /etc/ssh/ssh_host_rsa_key.pub
  hyrulecastle = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCpi5nzHpzQmwWZ+lVcJnrlTpKKqyNSS924TtqGeUSquXo87NFzXzy1vOqDFWK8x5FWMDWI8G+M0yY3UvBGYTuqG+O+cgozxfcDyDw51afGpfSRBwWoTyZKROFCebkERMms59snFFybyUh8hDFAzMHxiKoyqqaXuJ9yPLDNw+XIaqBO8CjT90+U7MqT1SPVjgwmLO+SD+SC43xZf+Y7iGgRIovkgqcddoHCaSS3XrtNRyv5/7F1J50XA8/3Qq57vpoRT4e8tEQaCm9GpQfQCECfckms3ipQnB3QQ/yheX78xpy0MMFvtySYhgkC9W9o2RRj2U9pDm8HsxOSyjoKrP3v80UF3Zf3SN9w3YmCb9JWOrbeM/mHsvNy7sQ1DG9iOFFbsp0phPPrufxoPejGBhXEOWVFUeq3OY0Yq6VfnRgDi1Ab15L+50NHh/Kw5vpYbZSgwPl4u1iE33x+lYMFnmokWndgyPBSkROSAKsMYhWoNbXWq4aWhRomVP3EMhyv+vgWqr2M9KYbfQHN0DMmFCAELx05QuIGb7nvX0OGT503Lfei+Q7uglEWv8L/C5z99uO/n19oYOC/ORoZFBIbFmGa2uyqhQamiViItu6J3+arx5PXAuENArDuT/MvBvwP6pd5kKnwqPMfNhUQNsoqTIeeirgM8pdBU9Moimkxzzpl2Q== root@nixos";
  kakariko = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDJqNkCOzPLhG3glgGXegN4dCOP7LOJ3ZPk9X5Q8yG+wLnPaAEN4RDxb1/EVqAo/cNoad8N7Whj68vFcBsNOXhtPnoM4bl30EItMv9r6OYYKuRS5vRaKYvyqT5FvPrk9loZuphWSPihDAdQ9qwDONl6ud2fIXozMRW2JXruVg3V+0HZy3Sv5rqtYjAQWqvO/791YNkxNbmMfj10UaG/1Ip80YdlPvk0FtvuSK/sgcsZt598wJ4W8z+aGVUKSilLnJ8LIzVLvTIMjwV0BR5+GqjcEZltb1+PcXPAxbJddwSCsW2NCcoekOWt85TvvkP7Pw1UND2g+PwJCMr1Q2fbt5aVojGgwEi9zzVGxACN2vOOgnkKLIEfm5Uywdllf0mcE4Zj6qgN8s773Mi8ZvwhwQJXpmYAwB3JHIr1j0okMqaAtbjqdMfyP0Fvt3epKDWqcTW1RqObQJkh5mcvoedxFcnygVkjoliumY6cdgb4cg/B+a+mv6zc0ON6UYVQKvLgUoodXjYqgMuR2EwgjN2tKFSVFqzY938/jSMpcMOcTmz1OOuo18G6ER791sCXyWS9k+nd48JFvQMDzrWe4yW8HmfD1wz5hdDz/7Rp698/DDni7DUsXxWlK3Wo0hD/z6UKgQNKpnuz+gz1yjUAj9iD5m2vBr/gf8DtJilvm+QA8iUerQ== root@nixos";
  skyloft = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCcxnXRmBcFrMY90gEJJvqtYqaQH7NLxXS6ndGzlciim78j+uEdk61gH+gRveHZMHIbycIHXvHGPEMKVHy3oIuudctmn88J36QHE1Y8bH8FrjDyBiCEgyOTnz3pRmS+YvsMJyPtC1UJBqnj0/MzorvS+HrFXCfNfWFDYSEj6/w0yHosqjsIhXjvQ/JIgaJvt+67xJlvsbYbbdtjijk+EmtxHtBB3ofKK2B0kUBbwYulbPzYKiZ/0sP/WtF5nm6DXt5DPpPYd4GAFx2lOVok38ZZuc2DyLM+lxMfMOTZied3RgTagly+VkhQtIHh+FNH5mY3JQnLRDxORa/+3BOFeaufCkewT8xRc8ZBbFMJJswRTiwVSwSr+2Phi+qy/+dUKuWrB2PLWgbqatwKc0RJ56EoPWOgIEqBFS30reO5N4BaNxiQGFpKqezkQ7vzDKpuI2FpLIruA+OAWZkHKBl0ZLs2jJ45SkkkvgACq4iCdjLBFYOUQ+GxNS/eaf4l/SvGF0ImzJnt2TlY6co69XuHlnqx9iebl9DXqh6ArYOZX1ZbarjaHCd2efeL0B6FThT50xyis8mSVrMchrfogf2oKr1JECaYcbLpujGt4FOXp/v45+W1ZIvIeR7UC2NA5J0na2LGmH3fXnuNcOmJg8Uu2V1dbH+ZL4XJZXznmnsVI0Eozw== root@nixOS-OracleArm";
  # mordor = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGdT6E0OwCh/fF1ji0ExyH+4zhh1znuoT+sCeDgYn9N1";

  systems = [ hyrulecastle kakariko skyloft ];

  # Backup keys
  # backup = "";
in
{
  # You need at least one to decrypt. These are the users and systems that will be able to decrypt the .age files later with their corresponding private keys.
  "my_identity.age".publicKeys = systems ++ users; # [hyrulecastle2];
  "free_games.age".publicKeys = systems ++ users;
}
