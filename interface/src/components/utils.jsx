export function convertIPFSURI(ipfsURI) {
  const ipfsPath = ipfsURI.replace('ipfs://', '');
          const pathSegments = ipfsPath.split('/');
          const lastSegment = pathSegments[pathSegments.length - 1];

          if (!isNaN(lastSegment)) {
            pathSegments[pathSegments.length - 1] = (
              parseInt(lastSegment) + 1
            ).toString();
          } else {
            pathSegments.push('1');
          }
    return pathSegments.join('/');
}