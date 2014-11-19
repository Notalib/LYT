'use strict';

angular.module('lyt3App')
  .value('LYTConfig', {
      // LYT.rpc function config
      rpc: {
        // The service's server-side URL
        url: '/DodpMobile/Service.svc' // No default - must be present
      },
      protocol: {
        // The reading system attrs to send with
        // the `setReadingSystemAttributes` request
        // (No default - must be present)
        readingSystemAttributes: {
          manufacturer: 'NOTA',
          model: 'LYT',
          serialNumber: '1',
          version: '1',
          config: null
        }
      },
      dtbDocument: {
        useForceClose: true,
        attempts: 3
      },
      service: {
        // The number of attempts to make when logging on
        // (multiple attempts are only made if the log on
        // process fails _unexpectedly_, i.e. connection
        // drops etc.) . If the server explicitly rejects
        // the username/password, `service` won't stupidly
        // try the same combo X more times.
        logOnAttempts: 3,
        guestUser: 'guest',
        guestLogin: 'guest'
      },
      segment: {
        preload: {
          queueSize: 3
        },
        imagePreload: {
          timeout: 1000000000,
          attempts: 5
        }
      },
      // NCCDocument config
      nccDocument: {
        metaSections: {
          //  Format is 'attribute value': 'attribute type'
          // 'title':             'class' # Don't skip the title and booknumber
          // 'dbbcopyright':      'class' # Don't skip copyright disclaimer
          'dbbintro': 'class',
          'rearcover': 'class',
          'summary': 'class',
          'rightflap': 'class',
          'leftflap': 'class',
          'extract': 'class',
          'authorbiography': 'class',
          'kolofon': 'class',
          'andre oplysninger': 'class',
          'andre titler': 'class',
          'oplysninger': 'class',
          'forord': 'class',
          'indhold': 'class',
          'acknowledgements': 'class',
          'tak': 'class',
          'dedication': 'class',
          'GBIB': 'id',
          'GINFO': 'id',
          'GFLAP': 'id'
        }
      },
  });
