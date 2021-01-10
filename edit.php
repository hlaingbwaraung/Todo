<?php

require'config.php';

if($_POST){
           $title=$_POST['title'];
           $desc=$_POST['description'];
           $id=$_POST['id'];

           $pdostatement=$pdo->prepare("UPDATE todo SET title='$title',description='$desc' WHERE id='$id'");
           $result =$pdostatement->execute();

           if($result){
              echo "<script>alert('New Todo is Updated');window.location.href='index.php';</script>";
            }
}
      else{
           $pdostatement=$pdo->prepare("SELECT * FROM todo WHERE id=".$_GET['id']);
           $pdostatement->execute();
           $result=$pdostatement->fetchAll();
}
?>

<!DOCTYPE html>
<html lang="en">
      <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>Create</title>
              <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css" integrity="sha384-ggOyR0iXCbMQv3Xipma34MD+dH/1fQ784/j6cY/iJTQUOhcWr7x9JvoRxT2MZw1T" crossorigin="anonymous">
      </head>
      <body>
            <div class="card">
                    <div class="card-body">
                            <h2>Edit New Todo</h2>
                            <form class=""action="" method="POST">
                                  <input type="hidden" name="id" value="<?php echo $result[0]['id']?>">
                                
                                 <div class="form-group">
                                       <label for="">Title</label>
                                       <input type="text"class="form-control"name="title" value="<?php echo $result[0]['title']?>" required>
                                 </div>
                                 <div class="form-group">
                                       <label for="">Decription</label>
                                       <textarea class="form-control" name="description"  rows="8" cols="80"required><?php echo $result[0]['description']?></textarea>
                                 </div>
                                 <div class="form-group">
                                       <input type="submit"class="btn btn-primary" name=""value="UPDATE">
                                       <a href="index.php" class="btn btn-secondary">Back</a>
                                 </div>
                            </form>
                    </div>
            </div>
     </body>
</html>