var mongoose = require('mongoose');
var Schema = mongoose.Schema;

var messageSchema = new Schema({
    text:  String,
    created_at: { type: Date, default: Date.now },
    received_at: Date,
    sender: {type: Schema.Types.ObjectId, index: true},
    recipients:   [Schema.Types.ObjectId]
});

module.exports = mongoose.model('Message', messageSchema);