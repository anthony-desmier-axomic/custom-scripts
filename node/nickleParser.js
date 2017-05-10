//Used for NIP001 to check the Files_To_Be_Migrated.csv file and to see if there were files in the same project that had JPG, PDF and TIF files of the same name
//If it did it would flag the JPG files to be removed as these were lower resolution. Ticket reference https://axomic.zendesk.com/agent/tickets/15037

var Transform = require('stream').Transform;
var csv = require('csv-streamify');
var JSONStream = require('JSONStream');

var csvToJson = csv({objectMode: true});
var projectArray = [];
var prjCode;

function arrayOperations(line){
    if(projectArray.length == 0){
        projectArray.push({fullline: line, projectCode: line[3], filename: line[1], extension: line[2]});
        //console.log('filling empty array');
        return null;
    } else if(projectArray.length > 0){

        prjCode = projectArray[0].projectCode;

        if(prjCode == line[3]){

            projectArray.push({fullline: line, projectCode: line[3], filename: line[1], extension: line[2]});
            //console.log('matched code: ' + line[3]);
            return null;

        } else {

            for(var j = 0; j < projectArray.length; j++){

                if(projectArray[j].extension == 'jpg'){
                    for(var k = 0; k < projectArray.length; k++){
                        if(projectArray[j].filename == projectArray[k].filename && projectArray[j].extension != projectArray[k].extension){
                            if(projectArray[k].extension == 'tif'){
                                projectArray[j].fullline[2] = 'remove';
                                //console.log(projectArray[j].extension);
                            } else if(projectArray[k].extension == 'pdf'){
                                projectArray[j].fullline[2] = 'remove';
                                //console.log(projectArray[j].extension);
                            }
                        }
                    }
                }

            }

            //clear project array and set next project code as first element
            var changedArray = projectArray;
            projectArray = [];
            projectArray.push({fullline: line, projectCode: line[3], filename: line[1], extension: line[2]});
            //console.log('New project...')
            return changedArray;

        }

    }
}



var parser = new Transform({objectMode: true});
parser._transform = function(line, encoding, done){

    var printArray = arrayOperations(line);
    var finalLine = '';

    if(printArray != null){

        for(var l = 0; l < printArray.length; l++){

            var newLine = printArray[l].fullline;

            for(var i = 0; i < newLine.length; i++){
                if(newLine[i].indexOf(',') > -1){
                    newLine[i] = '"' + newLine[i] + '"';
                }
            }

            finalLine += newLine.join(',');
            finalLine += '\r\n';

        }

        //this.push(finalLine);
        console.log(finalLine);
    }

    done();


}

var jsonToString = JSONStream.stringify(false);

process.stdin.pipe(csvToJson).pipe(parser);//.pipe(jsonToString).pipe(process.stdout);
process.stdout.on('error', process.exit);
