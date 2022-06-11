module netsim.network.nodes.docker.tap;

import netsim.network.nodes.docker.tap_dpp;

import std.format : format;
import std.process : execute;
import std.exception : enforce;
import std.string : toStringz;
import std.stdio : File;

enum IFNAME_MAXSIZE = IFNAMSIZ;

void createTap(string ifname)
in (ifname <= IFNAME_MAXSIZE)
{
  auto result = execute([
    "ip", "tuntap", "add", name, "mode", "tap", "user", "root"
  ]);
  enforce(result.status == 0,
    format!"ip tuntap add returned non-zero status code %d with output '%s'"(
      result.status,
      result.output
  ));
}

File openTap(string ifname)
in (ifname !is null)
in (ifname.length <= IFNAME_MAXSIZE)
{
  char* ifnamez = cast(char*) ifname.toStringz;

  int fd;

  // Todo: Clean this up

  ifreq ifr;
  ifr.ifr_ifrn.ifrn_name = 0;
  enum ifr_name_size = ifr.ifru_frn.ifrn_name.sizeof;
  if (snprintf(&ifr.ifr_ifrn.ifrn_name[0], ifr_name_size, "%s", ifnamez) >= ifr_name_size)
  {
    throw new Exception(format!"opentap failed: ifname is too long (limit: %d)"(IFNAMSIZ));
  }
  ifr.ifr_ifru.ifru_flags = IFF_TAP | IFF_NO_PI;

  if ((fd = open("/dev/net/tun".toStringz, O_RDWR)) == -1)
  {
    throw new Exception("opentap failed: open failed");
  }

  if (ioctl(fd, TUNSETIFF, &ifr) == -1)
  {
    close(fd);
    throw new Exception("opentap failed: ioctl failed");
  }

  // TODO: put errno and strerror in the exception

  assert(fd >= 0, "opentap failed: unknown error");

  File file;
  file.fdopen(fd, "rw");
  return file;
}
