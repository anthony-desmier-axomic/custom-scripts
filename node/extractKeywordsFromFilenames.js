//used for ATT001 to check for strings in the filename and extract them as keywords into an output file.
//Ticket reference https://axomic.zendesk.com/agent/tickets/13305

var readline = require('readline');
var fs = require('fs');

//KEYWORDS THAT THE FILENAME MIGHT START WITH
var startingExpression = [
    'exterior',
    'interior',
    'detail',
    'diagram',
    'plan',
    'site',
    'article',
    'graph',
    'elevation',
    'construction'
];

var startingExpressionRegEx = '^([A-Za-z]|[0-9]){4}(_|-| )';
var marketingExpressionRegEx = '^([A-Za-z]|[0-9]){4}(-| )';
var doNotUploadRegEx = '^proj_([A-Za-z]|[0-9]){4}(_|-| )';

//KEYWORDS TO SEARCH FOR IN FILENAME
var keywords = [
    'section',
    'water',
    'energy',
    'ventilation',
    'daylight',
    'labyrinth',
    'environmental section',
    'killer section',
    'schematic',
    'fan coil unit',
    'fcu',
    'chiller',
    'breem',
    'leed',
    'mechanical',
    'electrical',
    'public health',
    ' ph ',
    'mep',
    'masterplan',
    'master plan',
    'conditioning',
    'displacement',
    'chilled beam',
    'chilled ceiling',
    'sustainability implementation process',
    'SIP'
];



//ADD INPUT CSV FILENAME BELOW - I KNOW NEED TO UPDATE THIS TO USE CMD LINE ARGUMENTS
var rl = readline.createInterface({
    input: fs.createReadStream('ATT001_Staff_Output.csv')
});

rl.on('line', function(line){

    var assetConvention = '';
    var keywordString = '';
    var doNotUpload = '';
    var photographer = '';
    var projectProfile = '';
    var lineLength = line.length;
    var lastIndexOfSlash = line.lastIndexOf('/');
    var filename = line.substring(lastIndexOfSlash+1, lineLength);

    if(filename.includes('"')){
        filename = filename.replace('"', '');
    }

    //check for beginning of asset name conventions
    for(var i = 0; i < startingExpression.length; i++){

        var fullSearchString = startingExpressionRegEx + startingExpression[i];
        var regex = new RegExp(fullSearchString, 'i'); //case insensitive

        if(regex.test(filename)){
            assetConvention = startingExpression[i].charAt(0).toUpperCase() + startingExpression[i].substr(1); //capitalise first letter
        }

    }

    //check for individual asset keywords
    for(var j = 0; j < keywords.length; j++){

        var file = filename.toLowerCase();
        var keyword = keywords[j];

        if(file.includes(keyword)){
            keywordString = keywordString + keywords[j] + ';';
        }
        if(j == keywords.length-1){
            keywordString = keywordString.replace(/;\s*$/, ""); //remove last semi-colon
        }

    }

    //check for files being with _proj and tag as do not upload
    var regex = new RegExp(doNotUploadRegEx, 'i'); //case insensitive
    if(regex.test(filename)){
        doNotUpload = 'DO NOT UPLOAD'; //capitalise first letter
    }

    //check for marketing pdf
    var fileLength = filename.length;
    var extPos = filename.lastIndexOf('.');
    var extension = filename.substring(extPos+1, fileLength).toLowerCase();

    //check if files begins with Photographer_
    var photoBoolean = filename.startsWith('Photographer_');
    if(photoBoolean){
        var photoPos = filename.indexOf('_');
        photographer = filename.substring(photoPos+1, extPos);
    }

    var regex = new RegExp(marketingExpressionRegEx, 'i'); //case insensitive
    if(regex.test(filename)){
        if(extension == 'pdf'){
            projectProfile = 'Project Profile';
        }
    }


    var finalLine = line + ',' + assetConvention + ',' + keywordString + ',' + doNotUpload + ',' + projectProfile + ',' + photographer + '\r\n';



    fs.appendFile('out.csv', finalLine, function(err){
        if(err) throw err;
    });

});
