import 'package:get/get.dart';

import '../ember_core.dart';

class PathService extends GetxService {
  ClientContext clientContext = Get.find<ClientContext>();

  Future<String> _getPath(String collectionName, String domain, String? id) async {

    if (!CoreIdValidation.isValidDomain(domain)) {
      throw ArgumentError('Error getting path, invalid domain');
    }

    String outputPath;
    if (domain == 'rot') {
      outputPath = '';
    } else {
      outputPath = 'organization/';
    }

    String suffix;
    if (id == null) {
      suffix = collectionName;
    } else {
      CoreIdValidation.simpleValidate(id);
      suffix = '$collectionName/$id';
    }

    // TODO: Make this less horrible, but also work when seasonId and sessionId aren't set yet
    if (domain == 'org') {
      outputPath += await clientContext.getOrganizationId();
    } else if (domain == 'brn') {
      outputPath += '${await clientContext.getOrganizationId()}/branch/${await clientContext.getBranchId()}';
    } else if (domain == 'sea') {
      outputPath += '${await clientContext.getOrganizationId()}/branch/${await clientContext.getBranchId()}' '/season/${await clientContext.getSeasonId()}';
    } else if (domain == 'ses') {
      outputPath += '${await clientContext.getOrganizationId()}/branch/${await clientContext.getBranchId()}' '/season/${await clientContext.getSeasonId()}' '/session/${await clientContext.getSessionId()}';
    }

    if (outputPath.isEmpty) {
      return suffix;
    }
    return '$outputPath/$suffix';
  }

  Future<String> getDocPathFromId(String id) async {
    List<String> idParts = IdFunctions.getIdParts(id);
    return await _getPath(idParts[1], idParts[2], id);
  }

  Future<String> getCollectionPathFromId(String id) async {
    List<String> idParts = IdFunctions.getIdParts(id);
    return await _getPath(idParts[1], idParts[2], null);
  }

  Future<String> getCollectionPath(String collectionName, String domain) async {
    return await _getPath(collectionName, domain, null);
  }

}